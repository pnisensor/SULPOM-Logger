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

#if IOS_SIMULATOR

let fakeGyroRaw: [(Int16, Int16, Int16)] = [
    (5,3,0),(4,3,1),(5,6,0),
    (5,0,1),(5,3,0),(2,5,0),
    (5,2,-1),(3,1,2),(6,1,0),
    (5,2,1),(5,3,0),(3,4,0),
    (3,5,-1),(3,3,0),(4,0,0),
    (6,4,1),(4,2,0),(4,1,0),
    (4,3,1),(5,2,-1),(4,2,1),
    (6,2,0),(3,3,-2),(5,-1,0),
    (5,0,0),(5,5,-1),(6,1,-1),
    (5,5,-2),(3,4,1),(6,0,2),
    (3,2,0),(4,1,1),(7,1,-1),
    (4,3,2),(5,3,0),(3,4,-1),
    (5,-1,1),(3,2,1),(3,0,1),
    (4,2,-1),(3,3,-1),(5,1,1),
    (3,0,0),(5,5,-2),(5,4,2),
    (4,2,-1),(5,1,1),(5,2,-1),
    (2,3,0),(4,1,1),(6,3,-1),
    (3,1,-1),(5,3,0),(3,2,1),
    (5,1,0),(4,5,0),(6,0,2),
    (5,3,1),(6,1,-1),(5,3,0),
    (6,2,0),(5,2,-1),(4,2,0),
    (3,3,0),(5,1,-3),(5,3,-1),
    (5,0,0),(3,4,0),(6,4,1),
    (5,5,0),(5,0,1),(4,1,0),
    (4,3,0),(4,4,0),(5,2,1),
    (3,2,0),(3,2,0),(5,3,2),
    (4,1,-1),(4,5,1),(4,1,1),
    (4,0,1),(5,4,1),(4,4,0),
    (5,0,-1),(3,5,0),(5,3,0),
    (4,3,0),(4,6,0),(4,2,0),
    (5,2,1),(5,3,1),(5,4,-1),
    (4,4,-1),(4,1,-1),(4,1,-1),
    (5,4,-1),(4,1,-1),(4,4,-1),
    (5,4,2),(4,1,0),(3,3,1),
    (5,2,1),(3,2,0),(5,6,1),
    (3,4,1),(4,2,0),(4,-1,0),
    (4,4,0),(2,3,0),(5,9,46),
    (9,-2,193),(12,-7,411),(4,4,-70),
    (5,1,3),(7,2,-18),(36,-8,119),
    (653,-39,-174),(912,14,-158),(1186,-33,-93),
    (1646,-59,-259),(1709,-40,-123),(1827,-31,-97),
    (2035,-7,-16),(2394,8,-32),(2379,-16,-92),
    (2357,-42,-94),(2394,-16,-70),(2461,-59,-120),
    (2247,-12,-21),(1953,-4,-43),(1932,-63,-53),
    (1857,-67,-65),(1750,1,-18),(1696,-15,1),
    (1635,98,2),(1594,32,21),(1457,69,0),
    (1339,212,91),(1176,362,63),(1131,140,35),
    (1022,-13,46),(841,39,71),(694,-4,51),
    (360,26,-5),(189,-3,-9),(173,-3,-12),
    (119,0,-5),(-3,1,1),(-79,5,2),
    (-51,7,7),(9,1,0),(-27,0,7),
    (-57,5,0),(-78,3,8),(-82,3,3),
    (-137,3,-7),(-274,4,-10),(-379,-1,-16),
    (-525,12,-34),(-661,13,-24),(-804,12,-26),
    (-937,13,-26),(-1185,103,18),(-1288,83,10),
    (-1395,16,8),(-1556,14,9),(-1579,-71,-23),
    (-1702,-30,12),(-1866,-1,43),(-1908,22,24),
    (-1972,-17,-14),(-1987,-27,-7),(-2047,2,48),
    (-2093,13,31),(-2169,14,21),(-2112,7,24),
    (-2302,6,92),(-2305,36,75),(-1829,26,64),
    (-1623,21,5),(-1584,20,4),(-1257,20,23),
    (-1216,35,-5),(-1127,34,81),(-926,8,107),
    (-838,-5,12),(-447,-20,1),(-16,6,2),
    (-253,18,-2),(-382,47,-18),(18,5,1),
    (-2,3,-3),(-1,20,6),(4,1,-1),
    (3,6,3),(5,15,6),(8,11,-2),
    (7,9,-3),(6,-5,-1),(5,2,-4),
    (2,3,0),(25,32,1),(9,14,-1),
    (14,31,5),(14,39,8),(8,594,2),
    (24,963,-1),(14,1017,5),(1,1180,6),
    (5,1582,14),(8,1653,13),(9,1743,8),
    (51,2552,25),(28,2668,4),(147,2186,-227),
    (167,2214,-276),(129,2199,-108),(12,2876,-2),
    (26,2736,19),(-6,2540,8),(-14,1634,-15),
    (20,1608,9),(30,2136,16),(13,2756,2),
    (17,2709,8),(7,3031,9),(27,2555,-81),
    (14,-52,10),(3,-88,4),(6,4,-1),
    (3,10,0),(11,68,-3),(2,-46,5),
    (3,-60,6),(2,-50,8),(1,-139,24),
    (3,-190,24),(8,-429,28),(3,-730,21),
    (-2,-725,-12),(0,-1042,-4),(-10,-1248,-20),
    (-13,-1315,-13),(-1,-1570,-7),(5,-1571,-21),
    (-15,-1885,-19),(-3,-1740,-23),(14,-1221,-12),
    (7,-1578,-13),(-16,-2211,-21),(-30,-1478,-17),
    (1,-1689,-11),(-10,-1907,-24),(-5,-1406,-16),
    (9,-1458,-21),(11,-1930,-11),(4,-1910,-1),
    (-19,-1712,32),(-28,-1618,70),(-99,-1982,314),
    (-68,-2143,274),(-18,-1895,91),(-41,-1905,365),
    (-9,-2041,27),(18,-1445,-4),(-25,-95,26),
    (1,-19,9),(0,-25,17),(7,-21,9),
    (7,3,8),(8,-1,3),(6,-2,1),
    (-1,2,22),(12,1,380),(14,4,469),
    (8,-1,458),(20,3,715),(18,2,912),
    (22,-1,1107),(26,-2,1358),(38,-1,1820),
    (38,-1,2062),(42,-14,2509),(41,-14,2749),
    (47,-14,3151),(36,-12,2424),(24,-3,2092),
    (24,0,1807),(23,-10,1987),(26,-18,2218),
    (30,-12,1806),(20,-9,1596),(24,-12,1685),
    (23,-11,1628),(20,-3,1560),(28,-2,1486),
    (23,-12,1419),(18,-4,1547),(15,5,1573),
    (4,20,1138),(16,-6,877),(13,2,508),
    (7,2,161),(8,-3,151),(1,2,52),
    (14,3,97),(3,5,-2),(5,6,0),
    (7,3,-2),(9,0,-1),(2,-1,-11),
    (2,-5,-648),(-1,-2,-881),(-11,13,-1002),
    (-17,0,-1917),(-33,18,-2421),(-25,18,-2186),
    (-29,16,-2250),(-24,20,-1933),(-16,15,-1542),
    (-18,5,-1540),(-20,3,-1413),(-15,9,-1625),
    (-22,11,-1802),(-21,16,-1973),(-27,28,-2269),
    (-27,24,-2358),(-21,16,-2073),(-19,14,-1710),
    (-22,14,-1879),(-26,20,-2056),(-17,17,-1562),
    (-9,10,-1025),(-10,9,-1134),(-14,9,-1254),
    (-12,6,-1003),(-8,10,-847),(-2,7,-729),
    (-6,1,-766),(-1,6,-605),(0,-3,-539),
    (4,5,-430),(1,-2,-39),(7,-1,-36),
    (5,3,-157),(7,-7,-173),(10,-2,-110),
    (8,3,-25),(10,10,-5),(13,15,5),
    (9,15,3),(14,22,2),(2,6,-4),
    (1,2,0),(-9,16,11),(-5,-24,-316),
    (3,-5,-258),(6,1,5),(6,3,1),
    (5,2,1),(4,3,-2),(4,2,1),
    (6,5,0),(4,4,0),(6,1,2),
    (4,0,0),(5,5,-1),(5,0,0),
    (5,4,0),(4,3,1),(5,0,0),
    (4,3,1),(5,0,0),(4,4,1),
    (4,-1,0),(5,2,0),(5,3,0),
    (4,2,0),(4,1,-1),(5,3,1),
    (6,3,-1),(4,4,1),(3,2,1),
    (3,5,0),(5,3,-1),(5,2,1),
    (4,5,-1),(4,3,0),(4,3,1),
    (4,4,1),(4,2,0),(4,2,-1),
    (3,1,-1),(5,4,0),(4,1,1),
    (6,1,1),(6,2,0),(4,3,0),
    (5,2,2),(3,2,1),(3,2,-1),
    (3,4,0),(4,3,-1),(4,2,0),
    (5,4,-1),(5,0,0),(5,3,-1),
    (3,3,1),(5,4,0),(4,2,0),
    (2,2,0),(4,3,0),(2,2,-1),
    (4,2,1),(5,1,1),(5,3,0),
    (3,0,0),(4,2,0),(4,2,-1),
    (3,5,1),(6,3,1),(4,1,-1),
    (4,4,0),(3,2,1),(4,5,1),
    (5,0,-2),(4,2,1),(5,4,0),
    (5,4,-1),(4,6,1),(6,1,1),
    (4,3,1),(4,3,-1),(3,3,2),
    (4,3,0),(5,2,0),(2,2,-1),
    (4,3,0),(6,2,0),(3,4,1),
    (5,4,0),(4,2,0),(7,1,0),
    (3,3,0),(3,5,1),(4,2,1),
    (5,1,0),(5,4,1),(4,2,1),
    (5,4,0),(4,2,1),(4,6,0),
    (5,0,0),(4,2,0),(5,5,2),
    (4,2,0),(4,0,0),(6,2,-1),
    (5,1,0),(5,3,-1),(5,2,1),
    (4,1,0),(5,2,0),(3,1,0),
    (4,3,0),(5,1,-1),(5,1,1),
    (4,1,1),(4,3,1),(5,3,0),
    (4,5,1),(4,2,-1),(3,2,1),
    (4,2,1),(3,2,0),(5,4,0),
    (6,1,0),(4,1,1),(5,2,-1),
    (4,2,0),(3,3,1),(4,2,0),
    (4,3,-1),(6,5,0),(4,3,1),
    (5,0,0),(5,0,0),(4,3,1),
    (4,0,-1),(4,3,0),(4,1,1),
];

#endif // IOS_SIMULATOR