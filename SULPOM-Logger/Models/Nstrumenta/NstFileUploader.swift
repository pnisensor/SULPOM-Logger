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
import Alamofire

class NstFileUploader {
    typealias StartCb = (_ filename: String) -> Void
    typealias ProgressCb = (_ progress: Double) -> Void
    typealias ErrorCb = (_ msg: String) -> Void;
    typealias SuccessCb = (_ dataId: String) -> Void;
    
    public var onStart: StartCb?
    
    /// Callback with upload progress.
    public var onProgress: ProgressCb?;
    
    public var onError: ErrorCb?
    
    public var onSuccess: SuccessCb?
    
    public var apiKey: String = "";
    
    public var dataId: String?
    
    private var filenames: [String] = [];
    
    var tags: [String] = [];
    
    func uploadFiles(urls: [URL]) {
        uploadSingleFileFrom(urls: urls)
    }
    
    private func uploadSingleFileFrom(urls: [URL]) {
        var urls = urls;
        guard let url = urls.popLast() else { return; }
        uploadFile(dataUrl: url, onError: { [weak self] (msg) in
            self?.onError?(msg)
        }, onSuccess: { [weak self, urls] (resDataId) in
            guard let self = self else { return }
            self.filenames.append(url.lastPathComponent)
            if (self.dataId == nil) {
                self.dataId = resDataId;
            }
            
            if (urls.isEmpty) {
                self.updateMetadata(dataId: resDataId)
            } else {
                self.uploadSingleFileFrom(urls: urls);
            }
        });
    }
    
    private func uploadFile(dataUrl: URL, onError: @escaping ErrorCb, onSuccess: @escaping SuccessCb) {
        guard let size = try? dataUrl.resourceValues(forKeys: [.fileSizeKey]).allValues.first?.value as? Double else {
            let msg = "Failed to determine file size of '\(dataUrl.lastPathComponent)'.";
            print(msg);
            onError(msg)
            return;
        }
        
        onStart?(dataUrl.lastPathComponent)
        var dataId = dataId;
        getUploadDataUrl(dataUrl: dataUrl, size: size, dataId: dataId) { (err, res) in
            if let err = err {
                onError(err)
                return;
            }
            guard let res = res else {
                onError("No response received while getting upload data url")
                return;
            }
            dataId = res.dataId;
            guard let dataId = dataId else {
                onError("The current dataId is invalid")
                return
            }

            AF.upload(dataUrl, to: res.uploadUrl, method: .put)
                .validate()
                .cURLDescription { (description) in
                    print("Nstrumenta curl request: ", description);
                }
                .uploadProgress { [weak self] (progress: Progress) in
                    print(progress);
                    self?.onProgress?(progress.fractionCompleted);
                }
                .response { (afResponse: AFDataResponse<Data?>) in
                    switch (afResponse.result) {
                    case .success(let data):
                        print("...Nstrumenta request success!");
                        onSuccess(dataId)
    #if DEBUG
                        print("Actual response: ", afResponse.response as Any);
                        if let data: Data = data {
                            if let text: String = String(data: data, encoding: .utf8) {
                                print("Response message: ", text);
                            } else {
                                print("Response bytes: ", data.bytes);
                            }
                        }
    #endif
                    case .failure(let error):
                        let message: String;
                        if let statusCode: Int = error.responseCode, (statusCode == 413) {
                            var sizeMessage: String = "";
                            if let fileSize: Double = try? dataUrl.resourceValues(forKeys: [.fileSizeKey]).allValues.first?.value as? Double {
                                sizeMessage = String(format: " of size %.5gMB", fileSize / 1000000);
                            }
                            message = "The file\(sizeMessage) was too large to be uploaded.\nPlease save the file manually.";
                        } else {
                            message = error.underlyingError?.localizedDescription ?? error.localizedDescription;
                        }

                        print("...Nstrumenta request failed: ", message);
                        onError(message)
    #if DEBUG
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
                    }
                }
        }
    }
    
    private func getUploadDataUrl(dataUrl: URL, size: Double, dataId: String?,
                                  cb: @escaping (_ err: String?, _ res: GetUploadDataResp?) -> Void) {
        let headers: HTTPHeaders = [
            "x-api-key": apiKey,
            "Content-Type": "application/json",
            "Accept": "application/json",
        ];
        
        let parameters: [String: Any] = [
            "name": dataUrl.lastPathComponent,
            "size": size,
            "dataId": dataId as Any,
        ]
        
        AF.request(NstBase.Endpoints.getUploadData, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers)
            .validate()
            .responseDecodable(of: GetUploadDataResp.self) { (afResponse) in
                switch (afResponse.result) {
                case .success(let data):
                    #if DEBUG
                    print("...Nstrumenta request success!");
                    print("Actual response: ", afResponse.response as Any, data);
                    #endif
                    cb(nil, data);
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
                        msg = "Problem getting upload data url: \"\(text)\"."
                    } else {
                        msg = "Something went wrong getting upload data url: \(afMsg)"
                    }
                    if let code = error.responseCode {
                        msg += " Code (\(code)).";
                    }
                    #if DEBUG
                    print(msg);
                    #endif
                    cb(msg, nil)
                }
            }
    }
    
    private func updateMetadata(dataId: String) {
        let headers: HTTPHeaders = [
            "x-api-key": apiKey,
            "Content-Type": "application/json",
            "Accept": "text/html",
        ];
        
        // Note: other custom fields can be added to metadata and show up when
        // a query is done (better semantics than tags). Custom fields can't be
        // queried for with the current nst server architecture though, so those
        // are not used for now.
        let parameters: [String: Any] = [
            "metadata": [
                "filenames": filenames,
                "tags": tags,
            ] as [String: Any],
            "merge": true,
            "dataId": dataId as Any,
        ]
        
        AF.request(NstBase.Endpoints.setDataMetadata, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers)
            .validate()
            .responseString { [weak self] (afResponse) in
                switch (afResponse.result) {
                case .success(let data):
                    #if DEBUG
                    print("...Nstrumenta request success!");
                    print("Actual response: ", afResponse.response as Any, data);
                    #endif
                    self?.onSuccess?(dataId)
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
                        msg = "Problem getting upload data url: \"\(text)\"."
                    } else {
                        msg = "Something went wrong getting upload data url: \(afMsg)"
                    }
                    if let code = error.responseCode {
                        msg += " Code (\(code)).";
                    }
                    #if DEBUG
                    print(msg);
                    #endif
                    self?.onError?(msg)
                }
            }
    }
}
