//
//  Copyright © 2022 Protonex LLC dba PNI Sensor. All rights reserved.
//
//  This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as
//  published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License along with this program.
//  If not, see <https://www.gnu.org/licenses/>.
//

import Foundation
import Starscream
import Alamofire

protocol NstStreamingDelegate: AnyObject {
    func onNstStatusChanged(state: NstStreaming.State, visibility: Bool, error: String?);
    func onNstMessage(channel: String, dict: [String: Any])
}

struct GetTokenResp: Decodable {
    let token: String;
}

struct GetUploadDataResp: Decodable {
    let uploadUrl: String;
    let remoteFilePath: String;
    let dataId: String?;
}

enum BusMessageType {
    static let Json: UInt32   = 101;
    static let Buffer: UInt32 = 102;
}

fileprivate let serialQueue: DispatchQueue = DispatchQueue(label: "com.pnisensor.nst-queue");


/// This is an Nstrumenta Websocket client. It's goal is to mirror the functionality provided
/// by https://github.com/nstrumenta/nstrumenta/blob/main/src/browser/client.ts#L1
class NstStreaming: WebSocketDelegate {
    enum Channels {
        static let nstBase = "_nstrumenta";
        static let nstCommand = "_command"
    }
    
    static let jsonBytes = uint32ToBytes(value: BusMessageType.Json)
    
    static let BASE_TIMEOUT: Double = 5;
    
    enum State {
        case DISCONNECTED;
        case CONNECTING;
        case CONNECTED;
        case DISCONNECTING;
    }
    
    private struct StartLog: Encodable {
        let command: String = "startLog"
        let name: String;
        let channels: [String];
    }
    
    private struct FinishLog: Encodable {
        let command: String = "finishLog"
        let name: String;
    }
    
    static let shared = NstStreaming();
    
    weak var delegate: NstStreamingDelegate?;
    
    private(set) var state: State = .DISCONNECTED;
    
    private var socket: WebSocket?;
    private var hasVerified = false;
    private var token: String = "";
    private var reconnectAttempts = 0;
    private var currentWsUrl: URL?;
    private var currentApiKey: String = "";
    private var workItem: DispatchWorkItem?
    private var msgBuffer: [[UInt8]] = [];
    private var visibility = false;
    private var manualDisconnect = false;
    private var responseTimeout: DispatchWorkItem?
    private var subscriptions: [String] = [];
    
    private var logWasStarted = false;
    private var logStartDate = Date();
    private var logStartTimeout: DispatchWorkItem?
    
    
    // MARK: Methods
    
    deinit {
        disconnect(force: true);
    }
    
    func connect(wsUrl: URL, apiKey: String) {
        currentWsUrl = wsUrl;
        currentApiKey = apiKey;
        workItem?.cancel();
        workItem = nil;
        connect();
    }
    
    private func connect() {
        updateState(.CONNECTING);
        getToken(apiKey: currentApiKey) { [weak self] (token) in
            guard let self = self else { return }
            guard let url = self.currentWsUrl else {
                self.manualDisconnect = true;
                self.updateState(.DISCONNECTED, msg: "Nstrumenta URL not provided.")
                return;
            }
            
            self.hasVerified = true;
            self.token = token;
            var request = URLRequest(url: url)
            request.timeoutInterval = Self.BASE_TIMEOUT;
            let socket = WebSocket(request: request)
            socket.callbackQueue = serialQueue;
            self.socket = socket;
            socket.delegate = self
            
            // Starscream doesn't always reply, like if the url is wrong.
            let item = DispatchWorkItem { [weak self] in
                print("Timeout...")
                self?.updateState(.DISCONNECTING, msg: "No response from Nstrumenta Server.\nMake sure the URL is correct and the server is running.")
                socket.forceDisconnect();
            };
            self.responseTimeout = item;
            serialQueue.asyncAfter(deadline: .now() + Self.BASE_TIMEOUT * 2, execute: item);
            
            socket.connect()
        };
    }
    
    func disconnect(force: Bool = false) {
        updateState(.DISCONNECTING);

        if (force) {
            socket?.forceDisconnect()
        } else {
            serialQueue.asyncAfter(deadline: .now() + 1) { [weak self] in
                print("Telling socket to disconnect...")
                self?.socket?.disconnect()
            }
        }
    }
    
    func sendJson(channel: String, jsonMsg: String, ignoreQueue: Bool = false) {
        if (ignoreQueue) {
            serializeAndSend(channel: channel, json:  Data(jsonMsg.utf8))
        } else {
            serialQueue.async { [weak self] in
                self?.serializeAndSend(channel: channel, json:  Data(jsonMsg.utf8))
            }
        }
    }
    
    func sendJson(channel: String, jsonMsgData: Data) {
        serialQueue.async { [weak self] in
            self?.serializeAndSend(channel: channel, json: jsonMsgData)
        }
    }
    
    func serializeAndSend(channel: String, json: Data) {
        // Start is always thisfor json messages.
        var bytes: [UInt8] = Self.jsonBytes;
        
        // Encode channel with length.
        let channelData = Data(channel.utf8)
        bytes += Self.uint32ToBytes(value: UInt32(channelData.count))
        bytes += channelData.bytes
        
        // Encode json string message with length.
        bytes += UInt32(json.count).byteSwapped.bytes;
        bytes += json.bytes;
        sendBytes(bytes: bytes);
    }
    
    func startLog(name: String, channels: [String]) {
        let startLogStruct = StartLog(name: name, channels: channels);
        let encoder = JSONEncoder()
        do {
            let json =  try encoder.encode(startLogStruct)
            serialQueue.async { [weak self] in
                self?.serializeAndSend(channel: Channels.nstBase, json: json)
                self?.logWasStarted = true;
                self?.logStartDate = Date();
                
                // Failsafe incase no events are submitted after the delay period is over.
                let logStartTimeout = DispatchWorkItem { [weak self] in
                    guard let self = self else { return }
                    self.logWasStarted = false;
                    self.logStartTimeout = nil;
                    if (self.state == .CONNECTED || self.state == .DISCONNECTING), let socket = self.socket {
                        self.emptyMsgBuffer(socket: socket);
                    }
                }
                self?.logStartTimeout = logStartTimeout;
                serialQueue.asyncAfter(deadline: .now() + 1, execute: logStartTimeout);
            }
        } catch let error {
            print("Failed to encode json", error)
        }
    }
    
    func finishLog(name: String) {
        let finishLogStruct = FinishLog(name: name);
        let encoder = JSONEncoder()
        do {
            let json =  try encoder.encode(finishLogStruct)
            sendJson(channel: Channels.nstBase, jsonMsgData: json)
        } catch let error {
            print("Failed to encode json", error)
        }
    }
    
    func addSubscription(channel: String) {
        serialQueue.async { [weak self] in
            guard let self = self else { return }
            if (self.state == .CONNECTED) {
                self.sendSubscription(channel: channel)
            } else {
                self.subscriptions.append(channel)
            }
        }
    }
    
    private func sendSubscription(channel: String) {
        let msg = "{"
            + "\"command\":\"subscribe\","
            + "\"channel\":\"\(channel)\""
            + "}"
        print("Add subscription: ", msg)
        serializeAndSend(channel: Channels.nstCommand, json: Data(msg.utf8))
    }
    
    private func sendBytes(bytes: [UInt8]) {
        if (state == .CONNECTED || state == .DISCONNECTING), let socket = socket {
            if (logWasStarted) {
                // Some events seem to be missing from Nstrumenta logs when logging first starts.
                // Delay sending events for 1 second.
                if (Date().timeIntervalSince(logStartDate) >= 1) {
                    if let timeout = logStartTimeout {
                        timeout.cancel();
                        logStartTimeout = nil;
                    }
                    logWasStarted = false;
                } else {
                    msgBuffer.append(bytes);
                    return;
                }
            }
            
            if (!msgBuffer.isEmpty) {
                // First empty message buffer.
                emptyMsgBuffer(socket: socket);
            }
            
            socket.write(data: Data(bytes));
        } else {
            msgBuffer.append(bytes);
        }
    }
    
    private func emptyMsgBuffer(socket: WebSocket) {
        for msg in msgBuffer {
            socket.write(data: Data(msg));
        }
        msgBuffer.removeAll();
    }
    
    private func getToken(apiKey: String, cb: @escaping (_ token: String) -> Void) {
        let headers: HTTPHeaders = [
            "x-api-key": apiKey,
            "Content-Type": "application/json",
            "Accept": "application/json",
        ];

        print("Trying to get token...")
        AF.request(NstBase.Endpoints.getToken, method: .get, headers: headers)
            .validate()
            .responseDecodable(of: GetTokenResp.self) { [weak self] (afResponse) in
                switch (afResponse.result) {
                case .success(let data):
                    #if DEBUG
                    print("...Nstrumenta request success!");
//                    print("Actual response: ", afResponse.response as Any, data);
                    #endif
                    cb(data.token);
                case .failure(let error):
                    let afMsg = error.underlyingError?.localizedDescription ?? error.localizedDescription;
                    #if DEBUG
  
                    print("...Nstrumenta request failed: ", afMsg);
                    print("Error object: ", error);
                    print("Actual response: ", afResponse.response as Any);

                    if let data: Data = afResponse.data {
                        if let text: String = String(data: data, encoding: .utf8) {
                            print("Error response message: ", text);
                        } else {
                            print("Error response bytes: ", data.bytes);
                        }
                    }
                    #endif
                    
                    var msg: String;
                    if let code =  error.responseCode, ( code == 401) {
                        msg = "API Key Authorization failed.";
                    } else if let data = afResponse.data, let text = String(data: data, encoding: .utf8) {
                        msg = "Problem checking API Key: \"\(text)\"."
                    } else {
                        msg = "Something went wrong checking API Key: \(afMsg)"
                    }
                    if let code = error.responseCode {
                        msg += " Code (\(code)).";
                    }
                    #if DEBUG
                    print(msg);
                    #endif
                    self?.updateState(.DISCONNECTED, msg: msg);
                }
            }
    }
    
    private func deserialize(data: Data) {
//        #if DEBUG
//        print(BytesUtility.toHexString(bytes: data.bytes))
//        #endif
        
        let bytes = data.bytes;
        if (bytes.count < 8) {
            print("Failed to serialize message. Not enough available bytes to get message type and channel length.");
            return
        }
        
        let busMessageType = UInt32(fromBytes: [bytes[3], bytes[2], bytes[1], bytes[0]]);
        if (busMessageType != BusMessageType.Json && busMessageType != BusMessageType.Buffer) {
            print("Unknown BusMessageType: \(busMessageType)");
            return;
        }
        
        let channelLength = Int(UInt32(fromBytes: [bytes[7], bytes[6], bytes[5], bytes[4]]));
        var index = 8;
        if (bytes.count < index + channelLength) {
            print("Failed to serialize message. Channel length was longer than available bytes.");
            return;
        }
        guard let channel = Data(bytes.slice(startIndex: index, endIndex: index + channelLength)).toString() else {
            print("Failed to serialize message. Unable to interprate channel.");
            return;
        }
        index += channelLength;
        
        if (busMessageType == BusMessageType.Json) {
            if (bytes.count < index + 4) {
                print("Failed to serialize message. Not enough available bytes to get message length.");
                return;
            }
            let msgLength = Int(UInt32(fromBytes: [
                bytes[index + 3],
                bytes[index + 2],
                bytes[index + 1],
                bytes[index]
            ]));
            index += 4;
            if (bytes.count < index + msgLength) {
                print("Failed to serialize message. Message length was longer than available bytes.");
                return;
            }
            let msg = Data(bytes.slice(startIndex: index, endIndex: index + msgLength));
            
            do {
                if let dict = try JSONSerialization.jsonObject(with: msg, options: []) as? [String: Any] {
                    handleMessage(channel: channel, dict: dict);
                }
            } catch let error {
                print("Failed to serialize json for channel '\(channel)'. ", msg, error);
            }
        }
    }
    
    private func handleMessage(channel: String, dict: [String: Any]) {
//        #if DEBUG
//        print("\(Self.self) - Message: ", channel, dict);
//        #endif
        
        switch (channel) {
        case Channels.nstBase:
            #if DEBUG
            print("[\(Self.self)] \(channel): \(dict)");
            #endif
            if let error = dict["error"] as? String {
                print("Nstrumenta error: ", error);
            }
            if let verified = dict["verified"] as? Bool {
                if (verified) {
                    reconnectAttempts = 0;

                    // Send all subscriptions to the server.
                    for subscription in subscriptions {
                        sendSubscription(channel: subscription)
                    }
                    updateState(.CONNECTED);
                }
            }
        default:
            delegate?.onNstMessage(channel: channel, dict: dict)
        }
    }
    
    private static func uint32ToBytes(value: UInt32) -> [UInt8] {
        return value.bytes.reversed();
    }
    
    private func updateState(_ newState: State, msg: String? = nil) {
        let oldState = state;
        state = newState;
        if (oldState != newState) {
            delegate?.onNstStatusChanged(state: newState, visibility: visibility, error: msg);
        }
        
        if (state == .DISCONNECTED) {
            if (manualDisconnect) {
                manualDisconnect = false;
                socket = nil;
            } else if (hasVerified && reconnectAttempts < 100) {
                let delay = Double(min(reconnectAttempts * reconnectAttempts, 60))
                
                let workItem = DispatchWorkItem { [weak self] in
                    guard let self = self else { return }
                    self.reconnectAttempts += 1;
                    print("Attemping to reconnect...", self.reconnectAttempts);
                    self.connect();
                }
                self.workItem = workItem;
                DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: workItem)
            } else {
                socket = nil;
            }
        }
    }
    

    // MARK: WebSocketDelegate
    
    func didReceive(event: WebSocketEvent, client: WebSocket) {
        if let item = responseTimeout {
            item.cancel();
            responseTimeout = nil;
        }
        
        switch (event) {
        case .connected(let headers):
            print("\(Self.self) - WS connected. Headers: \(headers)");
            // Always send the token string as the first message.
            socket?.write(string: token);
        case .disconnected(let reason, let code):
            print("\(Self.self) - WS disconnected. Reason '\(reason)', code: '\(code)'.")
            updateState(.DISCONNECTED);
        case .text(let string):
            print("\(Self.self) - WS received text: \(string)")
        case .binary(let data):
            deserialize(data: data);
        case .ping(let ping):
            print("\(Self.self) - WS ping: ", ping as Any)
        case .pong(let pong):
            print("\(Self.self) - WS pong: ", pong as Any)
        case .viabilityChanged(let state):
            // NOTE: This seems to reflect whether the socket can access the internet.
            // Turning off WIFI results in this changing to false. During that time, no
            // health messages arrive. When WIFI is turned back on, this changes to true and
            // keep alives resume. It also seems that messages written during an outage
            // are sent when the outage ends.
            print("\(Self.self) - WS visibility changed: ", state);
            visibility = state;
            delegate?.onNstStatusChanged(state: self.state, visibility: visibility, error: nil)
        case .reconnectSuggested(let state):
            print("\(Self.self) - WS reconnect suggested: ", state);
        case .cancelled:
            print("\(Self.self) - WS conection cancelled.");
            manualDisconnect = true;
            updateState(.DISCONNECTED);
        case .error(let error):
            let errorMsg: String?
            if let error = error {
                errorMsg = "Error: \(error)"
            } else {
                errorMsg = nil;
            }
            print("\(Self.self) - WS error: \(error as Any)");
            updateState(.DISCONNECTED, msg: errorMsg);
        }
    }
}
