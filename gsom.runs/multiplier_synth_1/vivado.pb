
?
Command: %s
53*	vivadotcl2[
Gsynth_design -top multiplier -part xc7a35tcpg236-1 -mode out_of_context2default:defaultZ4-113h px? 
:
Starting synth_design
149*	vivadotclZ4-321h px? 
?
@Attempting to get a license for feature '%s' and/or device '%s'
308*common2
	Synthesis2default:default2
xc7a35t2default:defaultZ17-347h px? 
?
0Got license for feature '%s' and/or device '%s'
310*common2
	Synthesis2default:default2
xc7a35t2default:defaultZ17-349h px? 
V
Loading part %s157*device2#
xc7a35tcpg236-12default:defaultZ21-403h px? 
?
HMultithreading enabled for synth_design using a maximum of %s processes.4828*oasys2
42default:defaultZ8-7079h px? 
a
?Launching helper process for spawning children vivado processes4827*oasysZ8-7078h px? 
`
#Helper process launched with PID %s4824*oasys2
542182default:defaultZ8-7075h px? 
?
%s*synth2?
?Starting RTL Elaboration : Time (s): cpu = 00:00:05 ; elapsed = 00:00:09 . Memory (MB): peak = 2371.039 ; gain = 0.000 ; free physical = 862 ; free virtual = 18905
2default:defaulth px? 
?
synthesizing module '%s'%s4497*oasys2

multiplier2default:default2
 2default:default2i
S/home/aari/Projects/Vivado/gsom/gsom.gen/sources_1/ip/multiplier/synth/multiplier.v2default:default2
602default:default8@Z8-6157h px? 
?
synthesizing module '%s'%s4497*oasys2
LUT12default:default2
 2default:default2M
7/opt/Xilinx/Vivado/2020.2/scripts/rt/data/unisim_comp.v2default:default2
391372default:default8@Z8-6157h px? 
?
'done synthesizing module '%s'%s (%s#%s)4495*oasys2
LUT12default:default2
 2default:default2
12default:default2
12default:default2M
7/opt/Xilinx/Vivado/2020.2/scripts/rt/data/unisim_comp.v2default:default2
391372default:default8@Z8-6155h px? 
?
'done synthesizing module '%s'%s (%s#%s)4495*oasys2

multiplier2default:default2
 2default:default2
232default:default2
12default:default2i
S/home/aari/Projects/Vivado/gsom/gsom.gen/sources_1/ip/multiplier/synth/multiplier.v2default:default2
602default:default8@Z8-6155h px? 
?
%s*synth2?
?Finished RTL Elaboration : Time (s): cpu = 00:00:10 ; elapsed = 00:00:17 . Memory (MB): peak = 2376.961 ; gain = 5.922 ; free physical = 860 ; free virtual = 18910
2default:defaulth px? 
~
%s
*synth2f
R---------------------------------------------------------------------------------
2default:defaulth p
x
? 
M
%s
*synth25
!Start Handling Custom Attributes
2default:defaulth p
x
? 
~
%s
*synth2f
R---------------------------------------------------------------------------------
2default:defaulth p
x
? 
~
%s
*synth2f
R---------------------------------------------------------------------------------
2default:defaulth p
x
? 
?
%s*synth2?
?Finished Handling Custom Attributes : Time (s): cpu = 00:00:11 ; elapsed = 00:00:18 . Memory (MB): peak = 2391.805 ; gain = 20.766 ; free physical = 859 ; free virtual = 18909
2default:defaulth px? 
~
%s
*synth2f
R---------------------------------------------------------------------------------
2default:defaulth p
x
? 
~
%s
*synth2f
R---------------------------------------------------------------------------------
2default:defaulth p
x
? 
?
%s*synth2?
?Finished RTL Optimization Phase 1 : Time (s): cpu = 00:00:11 ; elapsed = 00:00:18 . Memory (MB): peak = 2391.805 ; gain = 20.766 ; free physical = 859 ; free virtual = 18909
2default:defaulth px? 
~
%s
*synth2f
R---------------------------------------------------------------------------------
2default:defaulth p
x
? 
?
r%sTime (s): cpu = %s ; elapsed = %s . Memory (MB): peak = %s ; gain = %s ; free physical = %s ; free virtual = %s
480*common2.
Netlist sorting complete. 2default:default2
00:00:00.022default:default2
00:00:00.022default:default2
2397.7422default:default2
0.0002default:default2
8522default:default2
189032default:defaultZ17-722h px? 
g
-Analyzing %s Unisim elements for replacement
17*netlist2
1002default:defaultZ29-17h px? 
j
2Unisim Transformation completed in %s CPU seconds
28*netlist2
02default:defaultZ29-28h px? 
K
)Preparing netlist for logic optimization
349*projectZ1-570h px? 
>

Processing XDC Constraints
244*projectZ1-262h px? 
=
Initializing timing engine
348*projectZ1-569h px? 
?
$Parsing XDC File [%s] for cell '%s'
848*designutils2i
S/home/aari/Projects/Vivado/gsom/gsom.gen/sources_1/ip/multiplier/multiplier_ooc.xdc2default:default2
inst	2default:default8Z20-848h px? 
?
-Finished Parsing XDC File [%s] for cell '%s'
847*designutils2i
S/home/aari/Projects/Vivado/gsom/gsom.gen/sources_1/ip/multiplier/multiplier_ooc.xdc2default:default2
inst	2default:default8Z20-847h px? 
?
Parsing XDC File [%s]
179*designutils2a
K/home/aari/Projects/Vivado/gsom/gsom.runs/multiplier_synth_1/dont_touch.xdc2default:default8Z20-179h px? 
?
Finished Parsing XDC File [%s]
178*designutils2a
K/home/aari/Projects/Vivado/gsom/gsom.runs/multiplier_synth_1/dont_touch.xdc2default:default8Z20-178h px? 
H
&Completed Processing XDC Constraints

245*projectZ1-263h px? 
?
r%sTime (s): cpu = %s ; elapsed = %s . Memory (MB): peak = %s ; gain = %s ; free physical = %s ; free virtual = %s
480*common2.
Netlist sorting complete. 2default:default2
00:00:002default:default2
00:00:002default:default2
2479.6172default:default2
0.0002default:default2
7752default:default2
188272default:defaultZ17-722h px? 
?
!Unisim Transformation Summary:
%s111*project2Z
F  A total of 5 instances were transformed.
  FDE => FDRE: 5 instances
2default:defaultZ1-111h px? 
?
r%sTime (s): cpu = %s ; elapsed = %s . Memory (MB): peak = %s ; gain = %s ; free physical = %s ; free virtual = %s
480*common24
 Constraint Validation Runtime : 2default:default2
00:00:00.042default:default2
00:00:00.032default:default2
2479.6172default:default2
0.0002default:default2
7752default:default2
188262default:defaultZ17-722h px? 
~
%s
*synth2f
R---------------------------------------------------------------------------------
2default:defaulth p
x
? 
?
%s*synth2?
?Finished Constraint Validation : Time (s): cpu = 00:00:17 ; elapsed = 00:00:25 . Memory (MB): peak = 2479.617 ; gain = 108.578 ; free physical = 841 ; free virtual = 18894
2default:defaulth px? 
~
%s
*synth2f
R---------------------------------------------------------------------------------
2default:defaulth p
x
? 
~
%s
*synth2f
R---------------------------------------------------------------------------------
2default:defaulth p
x
? 
V
%s
*synth2>
*Start Loading Part and Timing Information
2default:defaulth p
x
? 
~
%s
*synth2f
R---------------------------------------------------------------------------------
2default:defaulth p
x
? 
J
%s
*synth22
Loading part: xc7a35tcpg236-1
2default:defaulth p
x
? 
~
%s
*synth2f
R---------------------------------------------------------------------------------
2default:defaulth p
x
? 
?
%s*synth2?
?Finished Loading Part and Timing Information : Time (s): cpu = 00:00:17 ; elapsed = 00:00:25 . Memory (MB): peak = 2479.617 ; gain = 108.578 ; free physical = 841 ; free virtual = 18894
2default:defaulth px? 
~
%s
*synth2f
R---------------------------------------------------------------------------------
2default:defaulth p
x
? 
~
%s
*synth2f
R---------------------------------------------------------------------------------
2default:defaulth p
x
? 
Z
%s
*synth2B
.Start Applying 'set_property' XDC Constraints
2default:defaulth p
x
? 
~
%s
*synth2f
R---------------------------------------------------------------------------------
2default:defaulth p
x
? 
~
%s
*synth2f
R---------------------------------------------------------------------------------
2default:defaulth p
x
? 
?
%s*synth2?
?Finished applying 'set_property' XDC Constraints : Time (s): cpu = 00:00:17 ; elapsed = 00:00:25 . Memory (MB): peak = 2479.617 ; gain = 108.578 ; free physical = 841 ; free virtual = 18894
2default:defaulth px? 
~
%s
*synth2f
R---------------------------------------------------------------------------------
2default:defaulth p
x
? 
~
%s
*synth2f
R---------------------------------------------------------------------------------
2default:defaulth p
x
? 
?
%s*synth2?
?Finished RTL Optimization Phase 2 : Time (s): cpu = 00:00:17 ; elapsed = 00:00:26 . Memory (MB): peak = 2479.617 ; gain = 108.578 ; free physical = 832 ; free virtual = 18885
2default:defaulth px? 
~
%s
*synth2f
R---------------------------------------------------------------------------------
2default:defaulth p
x
? 
?
$decloning instance '%s' (%s) to '%s'223*oasys2[
Ginst/i_synth/MULT.OP/i_non_prim.R_AND_R/LOGIC.R_AND_R/EXTRA_LSB_BIT_DEL2default:default2*
delay__parameterized132default:default2\
Hinst/i_synth/MULT.OP/i_non_prim.R_AND_R/LOGIC.R_AND_R/EXTRA_LSB_RND1_DEL2default:defaultZ8-223h px? 
?
$decloning instance '%s' (%s) to '%s'223*oasys25
!inst/i_synth/DELAY_DIVIDE_BY_ZERO2default:default2*
delay__parameterized132default:default25
!inst/i_synth/DELAY_ACCUM_OVERFLOW2default:defaultZ8-223h px? 
?
$decloning instance '%s' (%s) to '%s'223*oasys25
!inst/i_synth/DELAY_DIVIDE_BY_ZERO2default:default2*
delay__parameterized132default:default2;
'inst/i_synth/DELAY_ACCUM_INPUT_OVERFLOW2default:defaultZ8-223h px? 
~
%s
*synth2f
R---------------------------------------------------------------------------------
2default:defaulth p
x
? 
L
%s
*synth24
 Start RTL Component Statistics 
2default:defaulth p
x
? 
~
%s
*synth2f
R---------------------------------------------------------------------------------
2default:defaulth p
x
? 
~
%s
*synth2f
R---------------------------------------------------------------------------------
2default:defaulth p
x
? 
O
%s
*synth27
#Finished RTL Component Statistics 
2default:defaulth p
x
? 
~
%s
*synth2f
R---------------------------------------------------------------------------------
2default:defaulth p
x
? 
~
%s
*synth2f
R---------------------------------------------------------------------------------
2default:defaulth p
x
? 
H
%s
*synth20
Start Part Resource Summary
2default:defaulth p
x
? 
~
%s
*synth2f
R---------------------------------------------------------------------------------
2default:defaulth p
x
? 
?
%s
*synth2j
VPart Resources:
DSPs: 90 (col length:60)
BRAMs: 100 (col length: RAMB18 60 RAMB36 30)
2default:defaulth p
x
? 
~
%s
*synth2f
R---------------------------------------------------------------------------------
2default:defaulth p
x
? 
K
%s
*synth23
Finished Part Resource Summary
2default:defaulth p
x
? 
~
%s
*synth2f
R---------------------------------------------------------------------------------
2default:defaulth p
x
? 
~
%s
*synth2f
R---------------------------------------------------------------------------------
2default:defaulth p
x
? 
W
%s
*synth2?
+Start Cross Boundary and Area Optimization
2default:defaulth p
x
? 
~
%s
*synth2f
R---------------------------------------------------------------------------------
2default:defaulth p
x
? 
~
%s
*synth2f
R---------------------------------------------------------------------------------
2default:defaulth p
x
? 
?
%s*synth2?
?Finished Cross Boundary and Area Optimization : Time (s): cpu = 00:00:19 ; elapsed = 00:00:27 . Memory (MB): peak = 2479.617 ; gain = 108.578 ; free physical = 818 ; free virtual = 18875
2default:defaulth px? 
~
%s
*synth2f
R---------------------------------------------------------------------------------
2default:defaulth p
x
? 
~
%s
*synth2f
R---------------------------------------------------------------------------------
2default:defaulth p
x
? 
R
%s
*synth2:
&Start Applying XDC Timing Constraints
2default:defaulth p
x
? 
~
%s
*synth2f
R---------------------------------------------------------------------------------
2default:defaulth p
x
? 
~
%s
*synth2f
R---------------------------------------------------------------------------------
2default:defaulth p
x
? 
?
%s*synth2?
?Finished Applying XDC Timing Constraints : Time (s): cpu = 00:00:26 ; elapsed = 00:00:34 . Memory (MB): peak = 2479.617 ; gain = 108.578 ; free physical = 675 ; free virtual = 18732
2default:defaulth px? 
~
%s
*synth2f
R---------------------------------------------------------------------------------
2default:defaulth p
x
? 
~
%s
*synth2f
R---------------------------------------------------------------------------------
2default:defaulth p
x
? 
F
%s
*synth2.
Start Timing Optimization
2default:defaulth p
x
? 
~
%s
*synth2f
R---------------------------------------------------------------------------------
2default:defaulth p
x
? 
~
%s
*synth2f
R---------------------------------------------------------------------------------
2default:defaulth p
x
? 
?
%s*synth2?
?Finished Timing Optimization : Time (s): cpu = 00:00:26 ; elapsed = 00:00:34 . Memory (MB): peak = 2479.617 ; gain = 108.578 ; free physical = 674 ; free virtual = 18732
2default:defaulth px? 
~
%s
*synth2f
R---------------------------------------------------------------------------------
2default:defaulth p
x
? 
~
%s
*synth2f
R---------------------------------------------------------------------------------
2default:defaulth p
x
? 
E
%s
*synth2-
Start Technology Mapping
2default:defaulth p
x
? 
~
%s
*synth2f
R---------------------------------------------------------------------------------
2default:defaulth p
x
? 
~
%s
*synth2f
R---------------------------------------------------------------------------------
2default:defaulth p
x
? 
?
%s*synth2?
?Finished Technology Mapping : Time (s): cpu = 00:00:26 ; elapsed = 00:00:34 . Memory (MB): peak = 2479.617 ; gain = 108.578 ; free physical = 670 ; free virtual = 18727
2default:defaulth px? 
~
%s
*synth2f
R---------------------------------------------------------------------------------
2default:defaulth p
x
? 
~
%s
*synth2f
R---------------------------------------------------------------------------------
2default:defaulth p
x
? 
?
%s
*synth2'
Start IO Insertion
2default:defaulth p
x
? 
~
%s
*synth2f
R---------------------------------------------------------------------------------
2default:defaulth p
x
? 
~
%s
*synth2f
R---------------------------------------------------------------------------------
2default:defaulth p
x
? 
Q
%s
*synth29
%Start Flattening Before IO Insertion
2default:defaulth p
x
? 
~
%s
*synth2f
R---------------------------------------------------------------------------------
2default:defaulth p
x
? 
~
%s
*synth2f
R---------------------------------------------------------------------------------
2default:defaulth p
x
? 
T
%s
*synth2<
(Finished Flattening Before IO Insertion
2default:defaulth p
x
? 
~
%s
*synth2f
R---------------------------------------------------------------------------------
2default:defaulth p
x
? 
~
%s
*synth2f
R---------------------------------------------------------------------------------
2default:defaulth p
x
? 
H
%s
*synth20
Start Final Netlist Cleanup
2default:defaulth p
x
? 
~
%s
*synth2f
R---------------------------------------------------------------------------------
2default:defaulth p
x
? 
~
%s
*synth2f
R---------------------------------------------------------------------------------
2default:defaulth p
x
? 
K
%s
*synth23
Finished Final Netlist Cleanup
2default:defaulth p
x
? 
~
%s
*synth2f
R---------------------------------------------------------------------------------
2default:defaulth p
x
? 
~
%s
*synth2f
R---------------------------------------------------------------------------------
2default:defaulth p
x
? 
?
%s*synth2?
?Finished IO Insertion : Time (s): cpu = 00:00:29 ; elapsed = 00:00:37 . Memory (MB): peak = 2479.617 ; gain = 108.578 ; free physical = 669 ; free virtual = 18727
2default:defaulth px? 
~
%s
*synth2f
R---------------------------------------------------------------------------------
2default:defaulth p
x
? 
~
%s
*synth2f
R---------------------------------------------------------------------------------
2default:defaulth p
x
? 
O
%s
*synth27
#Start Renaming Generated Instances
2default:defaulth p
x
? 
~
%s
*synth2f
R---------------------------------------------------------------------------------
2default:defaulth p
x
? 
~
%s
*synth2f
R---------------------------------------------------------------------------------
2default:defaulth p
x
? 
?
%s*synth2?
?Finished Renaming Generated Instances : Time (s): cpu = 00:00:29 ; elapsed = 00:00:37 . Memory (MB): peak = 2479.617 ; gain = 108.578 ; free physical = 669 ; free virtual = 18727
2default:defaulth px? 
~
%s
*synth2f
R---------------------------------------------------------------------------------
2default:defaulth p
x
? 
~
%s
*synth2f
R---------------------------------------------------------------------------------
2default:defaulth p
x
? 
L
%s
*synth24
 Start Rebuilding User Hierarchy
2default:defaulth p
x
? 
~
%s
*synth2f
R---------------------------------------------------------------------------------
2default:defaulth p
x
? 
~
%s
*synth2f
R---------------------------------------------------------------------------------
2default:defaulth p
x
? 
?
%s*synth2?
?Finished Rebuilding User Hierarchy : Time (s): cpu = 00:00:29 ; elapsed = 00:00:37 . Memory (MB): peak = 2479.617 ; gain = 108.578 ; free physical = 669 ; free virtual = 18727
2default:defaulth px? 
~
%s
*synth2f
R---------------------------------------------------------------------------------
2default:defaulth p
x
? 
~
%s
*synth2f
R---------------------------------------------------------------------------------
2default:defaulth p
x
? 
K
%s
*synth23
Start Renaming Generated Ports
2default:defaulth p
x
? 
~
%s
*synth2f
R---------------------------------------------------------------------------------
2default:defaulth p
x
? 
~
%s
*synth2f
R---------------------------------------------------------------------------------
2default:defaulth p
x
? 
?
%s*synth2?
?Finished Renaming Generated Ports : Time (s): cpu = 00:00:29 ; elapsed = 00:00:37 . Memory (MB): peak = 2479.617 ; gain = 108.578 ; free physical = 669 ; free virtual = 18727
2default:defaulth px? 
~
%s
*synth2f
R---------------------------------------------------------------------------------
2default:defaulth p
x
? 
~
%s
*synth2f
R---------------------------------------------------------------------------------
2default:defaulth p
x
? 
M
%s
*synth25
!Start Handling Custom Attributes
2default:defaulth p
x
? 
~
%s
*synth2f
R---------------------------------------------------------------------------------
2default:defaulth p
x
? 
~
%s
*synth2f
R---------------------------------------------------------------------------------
2default:defaulth p
x
? 
?
%s*synth2?
?Finished Handling Custom Attributes : Time (s): cpu = 00:00:29 ; elapsed = 00:00:37 . Memory (MB): peak = 2479.617 ; gain = 108.578 ; free physical = 669 ; free virtual = 18727
2default:defaulth px? 
~
%s
*synth2f
R---------------------------------------------------------------------------------
2default:defaulth p
x
? 
~
%s
*synth2f
R---------------------------------------------------------------------------------
2default:defaulth p
x
? 
J
%s
*synth22
Start Renaming Generated Nets
2default:defaulth p
x
? 
~
%s
*synth2f
R---------------------------------------------------------------------------------
2default:defaulth p
x
? 
~
%s
*synth2f
R---------------------------------------------------------------------------------
2default:defaulth p
x
? 
?
%s*synth2?
?Finished Renaming Generated Nets : Time (s): cpu = 00:00:29 ; elapsed = 00:00:37 . Memory (MB): peak = 2479.617 ; gain = 108.578 ; free physical = 669 ; free virtual = 18727
2default:defaulth px? 
~
%s
*synth2f
R---------------------------------------------------------------------------------
2default:defaulth p
x
? 
~
%s
*synth2f
R---------------------------------------------------------------------------------
2default:defaulth p
x
? 
K
%s
*synth23
Start Writing Synthesis Report
2default:defaulth p
x
? 
~
%s
*synth2f
R---------------------------------------------------------------------------------
2default:defaulth p
x
? 
A
%s
*synth2)

Report BlackBoxes: 
2default:defaulth p
x
? 
J
%s
*synth22
+-+--------------+----------+
2default:defaulth p
x
? 
J
%s
*synth22
| |BlackBox name |Instances |
2default:defaulth p
x
? 
J
%s
*synth22
+-+--------------+----------+
2default:defaulth p
x
? 
J
%s
*synth22
+-+--------------+----------+
2default:defaulth p
x
? 
A
%s*synth2)

Report Cell Usage: 
2default:defaulth px? 
E
%s*synth2-
+------+--------+------+
2default:defaulth px? 
E
%s*synth2-
|      |Cell    |Count |
2default:defaulth px? 
E
%s*synth2-
+------+--------+------+
2default:defaulth px? 
E
%s*synth2-
|1     |DSP48E1 |     2|
2default:defaulth px? 
E
%s*synth2-
|3     |LUT1    |     4|
2default:defaulth px? 
E
%s*synth2-
|4     |LUT2    |    47|
2default:defaulth px? 
E
%s*synth2-
|5     |LUT3    |   100|
2default:defaulth px? 
E
%s*synth2-
|6     |LUT4    |     9|
2default:defaulth px? 
E
%s*synth2-
|7     |LUT5    |    15|
2default:defaulth px? 
E
%s*synth2-
|8     |LUT6    |    19|
2default:defaulth px? 
E
%s*synth2-
|9     |MUXCY   |    50|
2default:defaulth px? 
E
%s*synth2-
|10    |SRL16E  |    16|
2default:defaulth px? 
E
%s*synth2-
|11    |XORCY   |    43|
2default:defaulth px? 
E
%s*synth2-
|12    |FDE     |     5|
2default:defaulth px? 
E
%s*synth2-
|13    |FDRE    |   303|
2default:defaulth px? 
E
%s*synth2-
+------+--------+------+
2default:defaulth px? 
~
%s
*synth2f
R---------------------------------------------------------------------------------
2default:defaulth p
x
? 
?
%s*synth2?
?Finished Writing Synthesis Report : Time (s): cpu = 00:00:29 ; elapsed = 00:00:37 . Memory (MB): peak = 2479.617 ; gain = 108.578 ; free physical = 669 ; free virtual = 18727
2default:defaulth px? 
~
%s
*synth2f
R---------------------------------------------------------------------------------
2default:defaulth p
x
? 
r
%s
*synth2Z
FSynthesis finished with 0 errors, 0 critical warnings and 0 warnings.
2default:defaulth p
x
? 
?
%s
*synth2?
?Synthesis Optimization Runtime : Time (s): cpu = 00:00:26 ; elapsed = 00:00:34 . Memory (MB): peak = 2479.617 ; gain = 20.766 ; free physical = 730 ; free virtual = 18788
2default:defaulth p
x
? 
?
%s
*synth2?
?Synthesis Optimization Complete : Time (s): cpu = 00:00:29 ; elapsed = 00:00:37 . Memory (MB): peak = 2479.617 ; gain = 108.578 ; free physical = 730 ; free virtual = 18788
2default:defaulth p
x
? 
B
 Translating synthesized netlist
350*projectZ1-571h px? 
?
r%sTime (s): cpu = %s ; elapsed = %s . Memory (MB): peak = %s ; gain = %s ; free physical = %s ; free virtual = %s
480*common2.
Netlist sorting complete. 2default:default2
00:00:052default:default2
00:00:00.022default:default2
2479.6172default:default2
0.0002default:default2
8132default:default2
188702default:defaultZ17-722h px? 
g
-Analyzing %s Unisim elements for replacement
17*netlist2
1002default:defaultZ29-17h px? 
j
2Unisim Transformation completed in %s CPU seconds
28*netlist2
02default:defaultZ29-28h px? 
K
)Preparing netlist for logic optimization
349*projectZ1-570h px? 
u
)Pushed %s inverter(s) to %s load pin(s).
98*opt2
02default:default2
02default:defaultZ31-138h px? 
?
r%sTime (s): cpu = %s ; elapsed = %s . Memory (MB): peak = %s ; gain = %s ; free physical = %s ; free virtual = %s
480*common2.
Netlist sorting complete. 2default:default2
00:00:002default:default2
00:00:002default:default2
2503.6412default:default2
0.0002default:default2
7562default:default2
188142default:defaultZ17-722h px? 
?
!Unisim Transformation Summary:
%s111*project2?
o  A total of 20 instances were transformed.
  (MUXCY,XORCY) => CARRY4: 15 instances
  FDE => FDRE: 5 instances
2default:defaultZ1-111h px? 
U
Releasing license: %s
83*common2
	Synthesis2default:defaultZ17-83h px? 
?
G%s Infos, %s Warnings, %s Critical Warnings and %s Errors encountered.
28*	vivadotcl2
232default:default2
02default:default2
02default:default2
02default:defaultZ4-41h px? 
^
%s completed successfully
29*	vivadotcl2 
synth_design2default:defaultZ4-42h px? 
?
r%sTime (s): cpu = %s ; elapsed = %s . Memory (MB): peak = %s ; gain = %s ; free physical = %s ; free virtual = %s
480*common2"
synth_design: 2default:default2
00:00:382default:default2
00:00:422default:default2
2503.6412default:default2
132.6802default:default2
9032default:default2
189602default:defaultZ17-722h px? 
?
 The %s '%s' has been generated.
621*common2

checkpoint2default:default2_
K/home/aari/Projects/Vivado/gsom/gsom.runs/multiplier_synth_1/multiplier.dcp2default:defaultZ17-1381h px? 
?
'%s' is deprecated. %s
384*common2#
use_project_ipc2default:default2A
-This option is deprecated and no longer used.2default:defaultZ17-576h px? 
?
<Added synthesis output to IP cache for IP %s, cache-ID = %s
485*coretcl2

multiplier2default:default2$
72bc90daf0b5c3bc2default:defaultZ2-1648h px? 
Q
Renamed %s cell refs.
330*coretcl2
742default:defaultZ2-1174h px? 
?
 The %s '%s' has been generated.
621*common2

checkpoint2default:default2_
K/home/aari/Projects/Vivado/gsom/gsom.runs/multiplier_synth_1/multiplier.dcp2default:defaultZ17-1381h px? 
?
%s4*runtcl2~
jExecuting : report_utilization -file multiplier_utilization_synth.rpt -pb multiplier_utilization_synth.pb
2default:defaulth px? 
?
Exiting %s at %s...
206*common2
Vivado2default:default2,
Wed Feb  9 22:26:34 20222default:defaultZ17-206h px? 


End Record