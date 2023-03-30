# Data Structure
The following documentation contains the majority of our frequently used variables throughout our program. We hope this will make our codebase more accessible to future contributors.
| Name      |      Data Structure      |  Description |
|-----------------------------|:----------------------------------:|---------------------------------:|
| %map_metal_to_rows_to_idx  |   [$metal] => [rows] => [row_idx]    | mapping metal to row to row indices      |
| %map_metal_to_cols_to_idx  |   [$metal] => [cols] => [col_idx]    | mapping metal to col to col indices      |
| %map_metal_to_rows       |   [$metal] => [rows]               | mapping metal to sorted row      |
| %map_metal_to_cols       |   [$metal] => [cols]               | mapping metal to sorted col      |
| %map_metal_to_vertices        |   [$metal] => [vertices]           | mapping current metal to correspoding vertices |
| %map_numTrackV                |   [$metal] => [numTrackV]          | mapping current metal to num of Vertical Track |KO
| %map_numTrackH                |   [$metal] => [numTrackH]          | mapping current metal to num of Horizontal Track |
| %vertices                     |   [$vertexName] => [@vertex]       | vertice collection |                     
| @vertex                       |   [0:$index][1:name] [2:Z-pos] [3:Y-pos] [4:X-pos] [5:ADJACENT_VERTICES]| vertices information|
| ADJACENT_VERTICES             |   [0:Left] [1:Right] [2:Front] [3:Back] [4:Up] [5:Down] [6:FL] [7:FR] [8:BL] [9:BR]|adjacent vertices|
| udEdges                       |   [0:$udEdgeIndex] [1:$udEdgeTerm1] [2:$udEdgeTerm2] [3:$vCost_34] [$vCost] | undirected edges between vertices |
| SOURCE or SINK                |   [netName] [#subNodes] [Arr. of sub-nodes, i.e., vertices]| Source/Sink information|
| inst                          |   [instName] [instType] [instWidth] [instY] | instance information |
| pins                          |   [PIN_NAME][NET_ID][pinIO][PIN_LENGTH][pinXpos][@pinYpos][INST_ID][PIN_TYPE] | pin information |
| h_pin_id                      |   [instance_idx_{S/G/D}] or [ext_{A/B/Y/VDD/VSS}] => [netID]  | mapping internal and external pins to its netID |
| nets                          |   [net]                            | net collection                  |
| net                           |   [netName] [netID] [N_pinNets] [$source_ofNet] [numSinks] [@sinks_inNet] [@pins_inNet] | net information |
| h_net_idx                     |   [netName] => [net_idx]           | mapping net name to net index           |
| h_inst_idx                    |   [instName] => [instance_idx]     | mapping instance name to instance index |
| h_pinId_idx                   |   [PIN_NAME] => [PIN_IDX]     | mapping pin name to pin index in pins        |
| h_pin_idx                     |   [Instance_name] => [PIN_IDX]    | mapping instance name to first pin ID |
| outerPin                      |   [PIN_NAME] [NETID] commodity     | mapping ext pin with net and commodity info |
| h_outerPin                    |   [PIN_NAME] => 1                  | mapping ext pin with 1 |
| VIRTUAL_EDGES                 |   [VIRTUAL_EDGE] | virtual edges collection |
| VIRTUAL_EDGE                  |   [index] [Origin] [Destination] [Cost=0] [instIdx] | virtual edge information |
| g_p_h1                        |   [instance_idx]                   | PMOS Gate in unit length 1 |
| g_p_h2                        |   [instance_idx]                   | PMOS Gate in unit length 2 |
| g_p_h3                        |   [instance_idx]                   | PMOS Gate in unit length 3 |
| n_p_h1                        |   [instance_idx]                   | NMOS Gate in unit length 1 |
| n_p_h2                        |   [instance_idx]                   | NMOS| VIRTUAL_EDGES                 |   [VIRTUAL_EDGE] | virtual edges collection |

# Varaible Naming
| Name                          |   Data Type   |      Data Structure      |  Description |
|-------------------------------|:-------------:|:----------------------------------:|---------------------------------:|
|N1_E_m1r0c0_m1r1c0 ()          |Bool           |     Net_1 Edge Metal_1 Row_0 Col_0 |
|N1_E_m1r1c2_pinMM0_1 ()        |Bool           |                                                           |
|N1_C0_E_m3r1c0_pinSON ()       |Bool           |     Net_1 Commodity_0 Edge Metal_3 Row_1 Col_0 |
|N1_C1_E_m1r0c0_m1r1c0  ()      |Bool           |     # N$nets[$netIndex][1]_C$commodityIndex\_E_$vName_1\_$vName_2 |
|N1_C1_E_m1r0c2_m1r1c2 ()       |Bool           |     # N$nets[$netIndex][1]_C$commodityIndex\_E_$vName_1\_$vName_2 |
|N1_C1_E_m1r3c2_pinMM1_1 ()     |Bool           |
|M_m1r0c2_pinMM1_1 ()           |Bool           |
|M_m4r3c5_m4r3c6 ()             |Bool           |     # M_$vName_s\_$vName_e
|M_m1r0c0_pinMM1_1 ()           |Bool           |
|M_m3r2c6_pinSON ()             |Bool           |
|ff1 ()                         |Bool           |     # instance flip flag
|x0 ()                          |(_ BitVec 7)   |     # instance x position: "%b", $numTrackV
|y0 ()                          |(_ BitVec 2)   |     # instance y position: "%b", $numPTrackH
|w1 ()                          |(_ BitVec 2)   |     # width: "%b", (2*$tmp_finger[0]+1)
|uw1 ()                         |(_ BitVec 2)   |     # unit width (normalized by num of fingers): "%b", $trackEachPRow
|nf1 ()                         |(_ BitVec 1)   |     # num of finger: "%b", $tmp_finger[0]
|GF_V_m1r0c0 ()                 |Bool           |     GF_V_$vName = GF_V_$"m".$metal."r".$row."c".$col
|GB_V_m3r3c6 ()                 |Bool           |     GB_V_$vName = GB_V_$"m".$metal."r".$row."c".$col
|GL_V_m2r0c0 ()                 |Bool           |     GL_V_$vName = GL_V_$"m".$metal."r".$row."c".$col
|GR_V_m2r0c0 ()                 |Bool           |     GR_V_$vName = GR_V_$"m".$metal."r".$row."c".$col
|C_N2_m4r3c6 ()                 |Bool           |     C_N$nets[$netIndex][1]\_$vName
|C_VIA_WO_N1_E_m2r3c2_m3r3c2 () |Bool           |     C_VIA_WO_N$nets[$netIndex][1]\_E\_$neighborName\_$neighborUp
|COST_SIZE_P ()                 |(_ BitVec 7)   |
|COST_SIZE_N ()                 |(_ BitVec 7)   |
|COST_SIZE ()                   |(_ BitVec 7)   |
|COST_Pin_C0 ()                 |Bool           |
|N1_M2_TRACK ()                 |Bool           |     N[h_extnets]\_M2\_TRACK
|N1_M2_TRACK_3 ()               |Bool           |     N[h_extnets]\_M2\_TRACK_[numTrackH-3]
|M2_TRACK_3 ()                  |Bool           |
| w_p_h1                        |   Integer     |              | total width of PMOS in unit length 1 |
| w_p_h2                        |   Integer     |              | total width of PMOS in unit length 2 |
| w_p_h3                        |   Integer     |              | total width of PMOS in unit length 3 |
| w_n_h1                        |   Integer     |              | total width of NMOS in unit length 1 |
| w_n_h2                        |   Integer     |              | total width of NMOS in unit length 2 |
| w_n_h3                        |   Integer     |              | total width of NMOS in unit length 3 |