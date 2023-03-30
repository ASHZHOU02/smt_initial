from cProfile import label
import os, sys
import re
import math
from enum import Enum
import numpy as np
import matplotlib.pyplot as plt
from matplotlib.patches import Rectangle
from itertools import cycle
from os import listdir
from os.path import isfile, join
from pathlib import Path
import gdspy
import logging
import json

logging.basicConfig(level=logging.INFO)

###Example:######################################################################################################
#                                                                                                               #
#   python3 genGDS_v4.0.py ./CFET/PNR_4.5T_Extend/solutionsSMT_cfet/ ./pinLayouts_cfet_v3.0/                    #
#                                                                                                               #
#                                                                                                               #
#################################################################################################################

# 2/12 TODO: This is messy. Fix later 
config_data = None

class BprMode(Enum):
    """
    Power Rail Location
    """
    NONE = 0
    METAL1 = 1
    METAL2 = 2
    BPR = 3

class MpoMode(Enum):
    """
    Minimum Pin Openining: minimum I/O acess points
    """
    NONE = 0
    TWO = 1
    THREE = 2
    MAX = 3

class GDSCellLibrary:
    def __init__(self, conv_path, pinlayout_path, bprFlag) -> None:
        # read argument
        self.conv_path = conv_path
        self.pinlayout_path = pinlayout_path
        # self.cpp_width = cpp_width
        self.bprFlag = bprFlag

        """
        Metal Pitch = MP Factor * Scaling
        """
        self.metalPitchM1=float(config_data['M1_MetalPitch']['value']) # cpp_width/2
        self.metalPitchM2=float(config_data['M2_MetalPitch']['value'])
        self.metalPitchM3=float(config_data['M3_MetalPitch']['value'])
        self.metalPitchM4=float(config_data['M4_MetalPitch']['value'])
        self.cppWidth = self.metalPitchM1 * 2
        # derive metal info: metal width = metal pitch / 2
        self.metalWidthM1 = self.metalPitchM1/2.0
        self.metalWidthM2 = self.metalPitchM2/2.0
        self.metalWidthM3 = self.metalPitchM3/2.0
        self.metalWidthM4 = self.metalPitchM4/2.0
        # meta info
        self.inst_cnt = 0
        self.metal_cnt = 0
        self.net_cnt = 0
        self.via_cnt = 0
        self.extpin_cnt = 0
        self.pin_cnt = 0
        # meta data structure
        self.metals = []
        self.instances = []
        self.vias = []
        self.extpins = []

        # datatype for GDSview
        self.PIN_DATATYPE = 3
        self.METAL_DATATYPE = 3
        self.SGD_DATATYPE = 3
        self.PWR_DATATYPE = 3
        self.SUB_DATATYPE = 1
        self.VIA_DATATYPE = 3 
        self.EXT_DATATYPE = 3
        self.PMOS_DATATYPE = 6
        self.NMOS_DATATYPE = 6

        # name mapping for matching .conv and .pinlayout
        self.instance_group = {}

        # layers different transistors
        self.layers = list(reversed(["substrate", "PWR", "PWR_label", "M0A_lower", "M0A_upper",
                        "Via12", "Via12_label", "M2", "Via23", "Via23_label", "M3",
                        "Via34", "Via34_label", "M4", "Ext", "Ext_label"]))
        self.assign_layer = {layer : idx for idx, layer in enumerate(self.layers)}
        # print(self.assign_layer)

        # Extract this information from pinlayout file
        self.pinlayout_files = [file for file in listdir(self.pinlayout_path) if isfile(join(self.pinlayout_path, file))]
        for pl_files in self.pinlayout_files:
            cell_meta_name = Path(pl_files).stem
            cell_name = cell_meta_name.split('_')[0]
            real_path = os.path.join(self.pinlayout_path, pl_files)
            logging.info("###### READING PINLAYOUT FILE INTO CELL: " + cell_name + " ######")
            self.instance_group[cell_name] = self.__readPinLayout__(real_path)

        # NMOS / PMOS Instance to determine M0A upper or lower (assign this manually)
        self.stack_struct_flag = "PN"

        # extract .conv files
        self.conv_files = [file for file in listdir(self.conv_path) if isfile(join(self.conv_path, file))]

        # initialize cell library
        self.cell_lib = gdspy.GdsLibrary()
        
        # load cells into library
        for conv_file in self.conv_files:
            cell_meta_name = Path(conv_file).stem
            cell_name = cell_meta_name.split('_')[0]
            real_path = os.path.join(self.conv_path, conv_file)
            logging.info("###### READING CONV FILE INTO CELL: " + cell_name + " ######")
            # add new cell
            temp_cell = self.cell_lib.new_cell(cell_meta_name)
            # read conv file
            self.__readConv__(temp_cell, real_path, cell_name)

        # save GDS file
        self.cell_lib.write_gds("cellLib.gds")

        # display all cells
        gdspy.LayoutViewer()

    def __readPinLayout__(self, pl_file):
        temp_dict = {}
        with open(pl_file) as fp:
            for line in fp:
                line_item = re.findall(r'\w+', line)

                # skip empty line
                if len(line_item) == 0:
                    # advance ptr
                    line = fp.readline()
                    continue

                # skip comments
                if re.search(r"\S", line)[0] == '#':
                    # advance ptr
                    line = fp.readline()
                    continue
                
                if re.match(r"insMM\d", line_item[1]):
                    instance_name = re.search( r'MM\d', line_item[1])
                    temp_dict[instance_name.group()] = line_item[2]
        return temp_dict

    def __readConv__(self, _cell, conv_file, cell_name):
        # [col, row] => metal obj
        pin_shape = {}
        # [col, row] = > pin obj 
        pin_loc = {}
        with open(conv_file) as fp:
            for line in fp:
                line_item = re.findall(r'\w+', line)

                # skip empty line
                if len(line_item) == 0:
                    # advance ptr
                    line = fp.readline()
                    continue

                # skip comments
                if re.search(r"\S", line)[0] == '#':
                    # advance ptr
                    line = fp.readline()
                    continue
                
                if line_item[0] == "COST":
                    num_cpp = int(int(line_item[1])/2)
                    # print(line_item[1])
                    # is this sufficient?
                    cell_width = (num_cpp + self.metalPitchM1) * 2
                elif line_item[0] == "TRACK":
                    num_track_v = int(line_item[1])
                    num_track_h = int(line_item[2])
                    if self.bprFlag == BprMode.METAL1 or self.bprFlag == BprMode.METAL2:
                        real_track = num_track_h + 2
                    elif self.bprFlag == BprMode.BPR:
                        real_track = num_track_h + 0.5
                    # ref to probe3, using M2 MP bc it has larger MP
                    cell_height = real_track * self.metalPitchM2
                    num_fin = num_track_h/2

                    # ld_place = {"layer": 10, "datatype": 26}
                    # for row in range(num_track_h):
                    #     inst_rect = gdspy.Rectangle((self.getLx(0, layer=0), self.getLy(row)), \
                    #         (self.getUx(int(num_track_v/2), layer=0), self.getUy(row)), **ld_place)
                    #     _cell.add(inst_rect)
                elif line_item[0] == "INST":
                    self.inst_cnt += 1
                    instance = self.Instance(   
                                                idx=int(line_item[1]),
                                                lx=int(line_item[2]),
                                                ly=int(line_item[3]),
                                                num_finger=int(line_item[4]),
                                                isFlip=int(line_item[5]),
                                                totalWidth=int(line_item[6]),
                                                unitWidth=int(line_item[7])
                                            )
                    self.instances.append(instance)
                    
                elif line_item[0] == 'METAL':
                    self.metal_cnt += 1
                    metal = self.Metal(
                                        layer=int(line_item[1]), 
                                        fromRow=int(line_item[2]), 
                                        fromCol=int(line_item[3]), 
                                        toRow=int(line_item[4]), 
                                        toCol=int(line_item[5]), 
                                        netID=int(line_item[6])
                                    )
                    self.metals.append(metal)
                    # metal layers
                    # NOTE: M1 is transistor layer with S/G/D
                    if metal.layer == 1:
                        ld_metal = {"layer": self.assign_layer["M0A_upper"], "datatype": self.METAL_DATATYPE}
                        metal_rect = gdspy.Rectangle((self.getLx(metal.fromCol, metal.layer), self.getLy(metal.fromRow)), \
                            (self.getUx(metal.toCol, metal.layer), self.getUy(metal.toRow)), **ld_metal)
                        _cell.add(metal_rect)
                    else: 
                        layer_name = "M{}".format(metal.layer)
                        ld_metal = {"layer": self.assign_layer[layer_name], "datatype": self.METAL_DATATYPE}
                        metal_rect = gdspy.Rectangle((self.getLx(metal.fromCol, metal.layer), self.getLy(metal.fromRow)), \
                            (self.getUx(metal.toCol, metal.layer), self.getUy(metal.toRow)), **ld_metal)
                        _cell.add(metal_rect)

                elif line_item[0] == "PIN" and len(line_item) == 4:
                    # Assuming all pins are on M1
                    self.pin_cnt += 1
                    pin = self.Pin(
                                    pinName=str(line_item[1]),
                                    row=int(line_item[2]),
                                    col=int(line_item[3])    
                                    )
                    offset_percent = 7000
                    ld_pin = {"layer": self.assign_layer["M0A_lower"], "datatype": self.PIN_DATATYPE}
                    ld_pin_label = {"layer": self.assign_layer["M0A_upper"]}
                    lx = self.getLx(pin.col,1)
                    ly = self.getLy(pin.row)
                    ux = self.getUx(pin.col,1)
                    uy = self.getUy(pin.row)
                    pin_rect = gdspy.Rectangle((lx, ly),(ux, uy),**ld_pin)
                    pin_label = gdspy.Label(pin.pinName, (lx + (ux - lx)/2, ly + (uy - ly)/2), **ld_pin_label)
                    _cell.add(pin_rect)
                    _cell.add(pin_label)
                    # [(PIN Column, PIN Row)] = Pin object
                    pin_loc[(pin.col, pin.row)] = pin
                elif line_item[0] == "VIA":
                    # NOTE: order is incorrect in original formulation
                    self.via_cnt += 1
                    via = self.Via( 
                                    fromMetal=int(line_item[1]), 
                                    toMetal=int(line_item[2]), 
                                    y=int(line_item[3]), 
                                    x=int(line_item[4]), 
                                    netID=1
                                    )
                    self.vias.append(via)
                    offset_percent = 7000
                    # extract layer name for assignment
                    layer_name = "Via{}{}".format(via.fromMetal, via.toMetal)
                    layer_label_name = layer_name + "_label"
                    ld_via = {"layer": self.assign_layer[layer_name], "datatype": self.VIA_DATATYPE}
                    ld_via_label = {"layer": self.assign_layer[layer_label_name]}
                    # TODO user min(MetalWidth)
                    fromMetal_width = self.getMetalWidth(via.fromMetal)
                    toMetal_width = self.getMetalWidth(via.toMetal)
                    if (fromMetal_width < toMetal_width):
                        lx = self.getLx(via.x, via.toMetal) + toMetal_width/offset_percent
                        ly = self.getLy(via.y)+ toMetal_width/offset_percent
                        ux = self.getUx(via.x, via.toMetal) - toMetal_width/offset_percent
                        uy = self.getUy(via.y)- toMetal_width/offset_percent
                    else:
                        lx = self.getLx(via.x, via.fromMetal) + fromMetal_width/offset_percent
                        ly = self.getLy(via.y)+ fromMetal_width/offset_percent
                        ux = self.getUx(via.x, via.fromMetal) - fromMetal_width/offset_percent
                        uy = self.getUy(via.y)- fromMetal_width/offset_percent

                    # print(self.getLx(via.x, via.fromMetal), via.fromMetal, offset_percent)
                    
                    via_rect = gdspy.Rectangle((lx, ly), (ux,uy),**ld_via)
                    via_label = gdspy.Label("VIA{}{}-{}".format(str(via.fromMetal), str(via.toMetal), str(via.netID)), (lx + (ux - lx)/2, ly + (uy - ly)/2), **ld_via_label)
                    _cell.add(via_rect)
                    _cell.add(via_label)

            # go through every metal location twice for P/N
            # for tmp_metal_col_row in pin_shape.keys():
            #     # if any of the pins are located at this metal
            #     tmp_metal = pin_shape[tmp_metal_col_row]
            #     # if current tmp_metal_col_row is 
            #     if tmp_metal_col_row in pin_loc.keys():
            #         # retrieve this pin
            #         tmp_pin = pin_loc[tmp_metal_col_row]
            #         # get pin location and check MM value
            #         instance_name = re.findall(r'\d+', tmp_pin.pinName)[0]
            #         # Instance
            #         if self.instance_group[cell_name]["MM{}".format(instance_name)] == "PMOS":
            #             if self.stack_struct_flag == "PN":
            #                 layer_name = "M0A_upper"
            #             else:
            #                 layer_name = "M0A_lower"
            #             # define ld metal
            #             ld_metal = {"layer": self.assign_layer[layer_name], "datatype": self.PMOS_DATATYPE}    
            #         elif self.instance_group[cell_name]["MM{}".format(instance_name)] == "NMOS":
            #             if self.stack_struct_flag == "NP":
            #                 layer_name = "M0A_upper"
            #             else:
            #                 layer_name = "M0A_lower"
            #             # define ld metal
            #             ld_metal = {"layer": self.assign_layer[layer_name], "datatype": self.NMOS_DATATYPE}
                    
            #         metal_rect = gdspy.Rectangle((self.getLx(tmp_metal.fromCol, tmp_metal.layer), self.getLy(tmp_metal.fromRow)), \
            #             (self.getUx(tmp_metal.toCol, tmp_metal.layer), self.getUy(tmp_metal.toRow)), **ld_metal)
                    
            #         # check if there is an another pin under the same col
            #         # assume pin access should either be top row or bottom row
            #         tmp_col, tmp_row = tmp_metal_col_row
            #         if tmp_row == 0:
            #             other_row = 3
            #         elif tmp_row == 3:
            #             other_row = 0

            #         # if upper layer and there is a pin access at the other side
            #         if (tmp_col, other_row) in pin_loc.keys() and layer_name == "M0A_upper":
            #             tmp_other_pin = pin_loc[(tmp_col, other_row)]
            #             ux = self.getUx(tmp_other_pin.col, layer=1)
            #             uy_1 = self.getUy(tmp_other_pin.row)
            #             uy_2 = self.getUy(tmp_other_pin.row + 1)
            #             # slice the current metal
            #             metal_rect = gdspy.slice(metal_rect, (uy_1 - uy_2)/1.5 + uy_2, axis=1, **ld_metal)[1]

            #         _cell.add(metal_rect)
            #     else:
            #         # TODO add NMOS
            #         # print(line_item)
            #         ld_metal = {"layer": self.assign_layer[layer_name], "datatype": self.PMOS_DATATYPE}    
            #         # a default PN setting?
            #         metal_rect = gdspy.Rectangle((self.getLx(tmp_metal.fromCol, tmp_metal.layer), self.getLy(tmp_metal.fromRow)), \
            #             (self.getUx(tmp_metal.toCol, tmp_metal.layer), self.getUy(tmp_metal.toRow)), **ld_metal)
            #         _cell.add(metal_rect)
        
            # cell boundary
            ld_boundary = {"layer": self.assign_layer["substrate"], "datatype": self.SUB_DATATYPE}
            boundary = gdspy.Rectangle((0, 0), (cell_width / 1000.0, cell_height / 1000.0), **ld_boundary)
            _cell.add(boundary)

            # Power Rail
            rectWidth = 0
            if self.bprFlag == BprMode.METAL1:
                # TODO move to upper
                ld_bpr = {"layer": self.assign_layer["PWR"], "datatype": self.PWR_DATATYPE}
                # TODO Assume Add PowerMetalWidth as parameter
                rectWidth = self.metalWidthM4
            elif self.bprFlag == BprMode.METAL2:
                # TODO move to upper
                ld_bpr = {"layer": self.assign_layer["PWR"], "datatype": self.PWR_DATATYPE}
            elif self.bprFlag == BprMode.BPR:
                ld_bpr = {"layer": self.assign_layer["PWR"], "datatype": self.PWR_DATATYPE}
                # TODO Assume Add PowerMetalWidth as parameter
                rectWidth = self.metalWidthM4
            
            lx = 0.0
            ly = (cell_height - rectWidth) / 1000.0
            ux = cell_width / 1000.0
            uy = (cell_height + rectWidth) /1000.0
            ld_pwr = {"layer":self.assign_layer["PWR_label"]}
            vdd_rect = gdspy.Rectangle((lx, ly), (ux, uy), **ld_bpr)
            vdd_label = gdspy.Label("VDD", (lx + (ux - lx)/2, ly + (uy - ly)/2), **ld_pwr)
            _cell.add(vdd_rect)
            _cell.add(vdd_label)

            lx = 0.0
            ly = (-rectWidth) / 1000.0
            ux = cell_width / 1000.0
            uy = (rectWidth) / 1000.0
            vss_rect = gdspy.Rectangle((lx, ly), (ux, uy), **ld_bpr)
            vss_label = gdspy.Label("VSS", (lx + (ux - lx)/2, ly + (uy - ly)/2), **ld_pwr)
            _cell.add(vss_rect)
            _cell.add(vss_label)
    
    def getMetalPitch(self, layer):
        if   layer == 1 : return self.metalPitchM1
        elif layer == 2 : return self.metalPitchM2
        elif layer == 3 : return self.metalPitchM3
        elif layer == 4 : return self.metalPitchM4
        else : raise ValueError("[ERROR] Invalid metal layer info.")
    
    def getMetalWidth(self, layer):
        if   layer == 1 : return self.metalWidthM1
        elif layer == 2 : return self.metalWidthM2
        elif layer == 3 : return self.metalWidthM3
        elif layer == 4 : return self.metalWidthM4
        else : raise ValueError("[ERROR] Invalid metal layer info.")

    def getLx(self, val, layer):
        if layer == 3:
            return (self.cppWidth/2 \
              + val - self.cppWidth/4)/1000.0
        elif layer == 4:
            return (self.cppWidth/2 \
              + val- self.metalWidthM3/2)/1000.0 - 0.009
        else:
            return (self.cppWidth/2 \
              + val - self.metalWidthM3/2)/1000.0

    # BPRMODE with METAL1 / METAL2 should shift coordinates by +metal_pitch/2.0
    def getLy(self, val):
        if self.bprFlag == BprMode.BPR:
            offset = 3 * self.metalPitchM2/4
        if self.bprFlag == BprMode.METAL1 or self.bprFlag == BprMode.METAL2:
            offset = 3 * self.metalPitchM2/2
        calVal = (offset \
          + val * self.metalPitchM2 - self.metalWidthM2/2)/1000.0
        return calVal

    def getUx(self, val, layer):
        if layer == 3:
            return (self.cppWidth/2 \
              + val + self.cppWidth/4)/1000.0
        elif layer == 4:
            return (self.cppWidth/2 \
              + val + self.metalWidthM3/2)/1000.0 + 0.009
        else:
            return (self.cppWidth/2 \
              + val + self.metalWidthM3/2)/1000.0

    # BPRMODE with METAL1 / METAL2 should shift coordinates by +metalPitch/2.0
    def getUy(self, val):
        if self.bprFlag == BprMode.BPR:
            offset = 3*self.metalPitchM2/4
        if self.bprFlag == BprMode.METAL1 or self.bprFlag == BprMode.METAL2:
            offset = 3*self.metalPitchM2/2
        calVal = (offset \
          + val * self.metalPitchM2 + self.metalWidthM2/2)/1000.0
        return calVal

    # Entity classes
    class Instance:
        def __init__(self, idx, lx, ly, num_finger, isFlip, totalWidth, unitWidth):
            self.idx = int(idx)
            self.lx = int(lx)
            self.ly = int(ly)
            self.num_finger = int(num_finger)
            self.isFlip = int(isFlip)
            self.totalWidth = int(totalWidth)
            self.unitWidth = int(unitWidth)

    class Metal:
        def __init__(self, layer, fromRow, fromCol, toRow, toCol, netID):
            self.layer = int(layer)
            self.fromRow = int(fromRow)
            self.fromCol = int(fromCol)
            self.toRow = int(toRow)
            self.toCol = int(toCol)
            if (netID != ''):
                self.netID = int(netID)
            else:
                self.netID = -1
            # 2/13 TODO: why dependency here, need fix
            # Depends on layer information, assign metal pitch
            if   layer == 1 : self.metalPitch = float(config_data['M1_MetalPitch']['value']) 
            elif layer == 2 : self.metalPitch = float(config_data['M2_MetalPitch']['value']) 
            elif layer == 3 : self.metalPitch = float(config_data['M3_MetalPitch']['value']) 
            elif layer == 4 : self.metalPitch = float(config_data['M4_MetalPitch']['value']) 
            else : raise ValueError("[ERROR] Invalid metal layer info.")

    class Via:
        # Choose smaller metal width as via width
        def __init__(self, fromMetal, toMetal, x, y, netID):
            self.fromMetal = int(fromMetal)
            self.toMetal = int(toMetal)
            self.x = int(x)
            self.y = int(y)
            self.netID = int(netID)

    class ExtPin:
        def __init__(self, layer, x, y, netID, pinName, isInput):
            self.layer = int(layer)
            self.x = int(x)
            self.y = int(y)
            self.netID = int(netID)
            self.pinName = pinName
            self.isInput = True if isInput.startswith("I") == True else False
    
    class Pin:
        def __init__(self, pinName, row, col):
            self.pinName = pinName
            self.row = int(row)
            self.col = int(col)


def main():
    args = sys.argv[1:]

    # if len(args) < 3:
    #     print("args no match!")
    #     exit(0)
    
    CONV_PATH = args[0]
    PINLAYOUT_PATH = args[1]
    CONFIG_PATH = args[2]
    json_file = open(CONFIG_PATH)
    global config_data # TODO fix this
    config_data = json.load(json_file)
    # Acquire MP from environment variable
    gdscelllib = GDSCellLibrary(CONV_PATH, PINLAYOUT_PATH, bprFlag=BprMode.BPR)

if __name__ == '__main__':
    main()
    