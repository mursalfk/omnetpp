#==========================================================================
#  MAIN.TCL -
#            part of OMNeT++
#==========================================================================

#----------------------------------------------------------------#
#  Copyright (C) 1992-2001 Andras Varga
#  Technical University of Budapest, Dept. of Telecommunications,
#  Stoczek u.2, H-1111 Budapest, Hungary.
#
#  This file is distributed WITHOUT ANY WARRANTY. See the file
#  `license' for details on this and other legal matters.
#----------------------------------------------------------------#

# vector config; numeric id can replace -
set vec(nextid) 0
set vec(-,title)  "(several vectors)"
set vec(-,fname)  ""
set vec(-,vecid)  ""
set vec(-,module) ""
set vec(-,name)   ""
set vec(-,mult)   ""
set vec(-,style)  ""
set vec(-,filter) ""
set vec(-,filtpars) ""
set vec(-,filtpfx) ""
set vec(-,zipped) ""

# filter descriptions
set filt(names)   ""
#set filt($name,type)
#set filt($name,descr)
#set filt($name,expr)

# internal vars
set g(listbox1) ""
set g(listbox2) ""
set g(status)   ""
set g(spaces)   [format {%200s} { }]
set g(tempfiles) ""

# config
set config(titlefmt)   "NAME in MODULE (FILENAME)"
set config(ofmt)       "%.10f"
set config(rightarrow) "copy"  ;# button with right arrow: move or copy vector
set config(grep)       "grep"
set config(zcat)       "zcat"
set config(gnuplot)    "gnuplot"
set config(awk)        "awk"
set config(mknod)      "mknod"
set config(sh)         "sh"
set config(gp-slash)   "1"   ;# use slash (not backslash) in filenames in gnuplot scripts (WIN32)

if [catch {set config(tmp) $env(TMP)}] {
    if [catch {set config(tmp) $env(TEMP)}] {
        if {$tcl_platform(platform) == "unix"} {
            set config(tmp) [file join / tmp]
        } else {
            set config(tmp) [file join / temp]
        }
    }
}

set config(vectorfile)       ""
set config(scriptfile)       "plove.sh"
set config(configfile)       "~/.ploverc"
set config(vectorconfigfile) "plove.cfg"

# gnuplot options
set gp(title)   ""
set gp(xlabel)  ""
set gp(ylabel)  ""
set gp(xrange)  ""
set gp(yrange)  ""
set gp(xtics)   ""
set gp(ytics)   ""
set gp(before)  \
"## place for gnuplot commands like:
# set logscale y
# set noxtics
# set tics out
# set arrow to 10,2"
set gp(after) ""
set gp(picterm) "postscript eps color"
set gp(picfile) "pic1.eps"


proc createMenubar {w} {

    global g tcl_version

    #################################
    # Menu bar
    #################################

    # Create menus
    foreach i {
       {filemenu     -$label_opt File -underline 0}
       {leftmenu     -$label_opt Left -underline 0}
       {rightmenu    -$label_opt Right -underline 0}
       {optionsmenu  -$label_opt Options -underline 0}
       {helpmenu     -$label_opt Help -underline 0}
    } {
       if {$tcl_version < 8.0} {
           set label_opt "text"; set m ".m"
           set mb [eval menubutton $w.$i -padx 4 -pady 3]
           menu $mb.m -tearoff 0
           $mb config -menu $mb.m
       } else {
           set label_opt "label"; set m ""
           eval $w add cascade -menu $w.$i
           menu "$w.[lindex $i 0]" -tearoff 0
       }
    }

    # File menu
    foreach i {
      {command -command fileOpen -label {Load vector...} -underline 0}
      {separator}
      {command -command loadVectorConfig -label {Open vector config...} -underline 0}
      {command -command saveVectorConfig -label {Save vector config...} -underline 0}
      {separator}
      {command -command saveScript -label {Save shell script...} -underline 6}
      {command -command savePicture -label {Save picture...} -underline 5}
      {separator}
      {command -command fileExit -label Exit -underline 1}
    } {
       eval $w.filemenu$m add $i
    }

    # Left menu
    foreach i {
      {command -command {selectVectors 1} -label {Select...  +} -underline 0}
      {command -command {selectAll 1} -label {Select all} -underline 7}
      {command -command {invertSelection 1} -label {Invert selection  *} -underline 0}
      {separator}
      {command -command {vectorInfo 1} -label {Vector info...  F3} -underline 8}
      {command -command {editVectorFilters 1} -label {Vector plotting options...  F4} -underline 7}
      {separator}
      {command -command {replaceInTitles 1} -label {Find+Replace in titles...} -underline 5}
      {separator}
      {command -command {moveVectors 1 2} -label {Move  F5} -underline 0}
      {command -command {copyVectors 1 2} -label {Copy  F6} -underline 0}
      {command -command {dupVectors 1} -label {Duplicate} -underline 1}
      {command -command {delVectors 1} -label {Delete  Del,F8} -underline 0}
    } {
      eval $w.leftmenu$m add $i
    }

    # Right menu
    foreach i {
      {command -command {selectVectors 2} -label {Select...} -underline 0}
      {command -command {selectAll 2} -label {Select all} -underline 7}
      {command -command {invertSelection 2} -label {Invert selection} -underline 0}
      {separator}
      {command -command {vectorInfo 2} -label {Vector info...  F3} -underline 8}
      {command -command {editVectorFilters 2} -label {Vector plotting options...  F4} -underline 7}
      {separator}
      {command -command {replaceInTitles 2} -label {Find+Replace in titles...} -underline 5}
      {separator}
      {command -command {moveVectors 2 1} -label {Move  F5} -underline 0}
      {command -command {copyVectors 2 1} -label {Copy  F6} -underline 0}
      {command -command {dupVectors 2} -label {Duplicate} -underline 1}
      {command -command {delVectors 2} -label {Delete  Del,F8} -underline 0}
    } {
      eval $w.rightmenu$m add $i
    }

    # Options menu
    foreach i {
      {command -command editGeneralOptions -label {General options...} -underline 0}
      {command -command editGnuplotOptions -label {Gnuplot options...} -underline 3}
      {command -command editFilterConfig -label {Filter configuration...} -underline 0}
      {command -command editExtProgs -label {External programs...} -underline 0}
      {separator}
      {command -command loadConfig -label {Load config...} -underline 5}
      {command -command saveConfig -label {Save config...} -underline 0}
    } {
      eval $w.optionsmenu$m add $i
    }

    # Help menu
    foreach i {
      {command -command helpAbout -label {About OMNeT++ Plove...} -underline 0}
      {command -command helpReadme -label {README...} -underline 0}
    } {
      eval $w.helpmenu$m add $i
    }

    # Pack menu buttons on menubar
    if {$tcl_version < 8.0} {
        foreach i {
          filemenu leftmenu rightmenu optionsmenu helpmenu
        } {
          pack $w.$i -anchor n -expand 0 -fill none -side left
        }
    }
}

proc createMainArea {w} {

    global g fonts

    frame $w.f1 -relief flat -border 2 ;# all vectors
    frame $w.f2 -relief flat -border 2 ;# add/remove buttons
    frame $w.f3 -relief flat -border 2 ;# plotted vectors
    frame $w.f4 -relief flat -border 2 ;# plot, save etc. action buttons

    pack $w.f4 -expand 0 -fill both -side right -anchor w -padx 3 -pady 3
    pack $w.f1 -expand 1 -fill both -side left -anchor w -padx 3 -pady 3
    pack $w.f2 -expand 0 -fill both -side left -anchor w -padx 3 -pady 3
    pack $w.f3 -expand 1 -fill both -side left -anchor w -padx 3 -pady 3

    #
    # Pane 1
    #
    label $w.f1.tit -font $fonts(bold) -bg #e0e080 -text {Vector Store}
    pack $w.f1.tit -anchor center -expand 0 -fill x -side top -pady 3

    frame $w.f1.but
    button $w.f1.but.load -text {Load...} -command fileOpen
    button $w.f1.but.sel  -text {Sel...}  -command {selectVectors 1}
    button $w.f1.but.repl -text {Repl...} -command {replaceInTitles 1}
    button $w.f1.but.del  -text {Delete}  -command {delVectors 1}
    pack $w.f1.but -expand 0 -fill x -side bottom
    pack $w.f1.but.load -side left -expand 1 -fill x
    pack $w.f1.but.sel  -side left -expand 1 -fill x
    pack $w.f1.but.repl -side left -expand 1 -fill x
    pack $w.f1.but.del  -side left -expand 1 -fill x

    label $w.f1.status -relief groove
    pack $w.f1.status -expand 0 -fill x -side bottom

    frame $w.f1.main
    listbox $w.f1.main.list -width 20 -selectmode extended -exportselection 0 \
        -yscrollcommand "$w.f1.main.sby set"
    scrollbar $w.f1.main.sby -borderwidth 1 -command "$w.f1.main.list yview"

    pack $w.f1.main.sby -anchor s -expand 0 -fill y -side right
    pack $w.f1.main.list  -anchor center -expand 1 -fill both -side left
    pack $w.f1.main -anchor center -expand 1 -fill both -side top

    set g(listbox1) $w.f1.main.list
    set g(status1) $w.f1.status

    #
    # Pane 2
    #
    set rightarrow [image create bitmap -data {
      #define right_width 12
      #define right_height 15
      static unsigned char right_bits[] = {
        0x10, 0x00, 0x30, 0x00, 0x60, 0x00, 0xe0, 0x00, 0xc0, 0x01, 0x7f, 0x02,
        0xab, 0x05, 0xff, 0x0f, 0xff, 0x07, 0xff, 0x03, 0xc0, 0x01, 0xe0, 0x00,
        0x60, 0x00, 0x30, 0x00, 0x10, 0x00};
    }]
    set leftarrow [image create bitmap -data {
     #define left_width 12
     #define left_height 15
     static unsigned char left_bits[] = {
       0x80, 0x00, 0xc0, 0x00, 0x60, 0x00, 0x70, 0x00, 0x38, 0x00, 0xe4, 0x0f,
       0x5a, 0x0d, 0xff, 0x0f, 0xfe, 0x0f, 0xfc, 0x0f, 0x38, 0x00, 0x70, 0x00,
       0x60, 0x00, 0xc0, 0x00, 0x80, 0x00};
    }]

    frame $w.f2.dum1
    button $w.f2.add -image $rightarrow -height 30 -width 22 -command {moveOrCopyVectors 1 2}
    button $w.f2.back -image $leftarrow -height 30 -width 22 -command {moveVectors 2 1}
    frame $w.f2.dum2

    pack $w.f2.dum1 -anchor center -fill x -expand 1
    pack $w.f2.add -anchor center -fill x -expand 0
    pack $w.f2.back -anchor center -fill x -expand 0
    pack $w.f2.dum2 -anchor center -fill x -expand 1

    #
    # Pane 3
    #
    label $w.f3.tit -font $fonts(bold) -bg #e0e080 -text {Ready-to-Plot Vectors}
    pack $w.f3.tit -anchor center -expand 0 -fill x -side top -pady 3

    frame $w.f3.but
    button $w.f3.but.opt -text {Info...} -command {vectorInfo 2}
    button $w.f3.but.fil -text {Options...} -command {editVectorFilters 2}
    button $w.f3.but.del -text {Delete} -command {delVectors 2}
    button $w.f3.but.dup -text {Dup} -command {dupVectors 2}

    pack $w.f3.but -expand 0 -fill x -side bottom
    pack $w.f3.but.opt -side left -expand 1 -fill x
    pack $w.f3.but.fil -side left -expand 1 -fill x
    pack $w.f3.but.del -side left -expand 1 -fill x
    pack $w.f3.but.dup -side left -expand 1 -fill x

    label $w.f3.status -relief groove
    pack $w.f3.status -expand 0 -fill x -side bottom

    frame $w.f3.main
    listbox $w.f3.main.list -width 20 -selectmode extended -exportselection 0 \
        -yscrollcommand "$w.f3.main.sby set"
    scrollbar $w.f3.main.sby -borderwidth 1 -command "$w.f3.main.list yview"

    pack $w.f3.main.sby -anchor s -expand 0 -fill y -side right
    pack $w.f3.main.list  -anchor center -expand 1 -fill both -side left
    pack $w.f3.main -anchor center -expand 1 -fill both -side top

    set g(listbox2) $w.f3.main.list
    set g(status2) $w.f3.status

    #
    # Pane 4
    #
    frame $w.f4.dum1
    button $w.f4.opt  -text {Options...} -command editGnuplotOptions
    button $w.f4.plot -text {PLOT!} -command doPlot -height 2
    button $w.f4.pic -text {Save picture...} -command savePicture
    button $w.f4.script -text {Save script...} -command saveScript
    button $w.f4.conf -text {Save vec cfg...} -command saveVectorConfig
    frame $w.f4.dum2

    pack $w.f4.dum1 -anchor center -fill x -expand 1
    pack $w.f4.opt -anchor center -fill x -expand 0
    pack $w.f4.plot -anchor center -fill x -expand 0 -pady 8
    pack $w.f4.pic -anchor center  -fill x -expand 0
    pack $w.f4.script -anchor center -fill x -expand 0
    pack $w.f4.conf -anchor center  -fill x -expand 0 -pady 8
    pack $w.f4.dum2 -anchor center -fill x -expand 1

    #
    # Popup menus
    #
    menu .left_popup -tearoff 0
    foreach i {
      {command -command {vectorInfo 1} -label {Info...  F3} -underline 0}
      {command -command {editVectorFilters 1} -label {Plotting options...  F4} -underline 0}
      {separator}
      {command -command {replaceInTitles 1} -label {Find+Replace in titles...} -underline 5}
      {separator}
      {command -command {moveVectors 1 2} -label {Move  F5} -underline 0}
      {command -command {copyVectors 1 2} -label {Copy  F6} -underline 0}
      {command -command {dupVectors 1} -label {Duplicate} -underline 1}
      {command -command {delVectors 1} -label {Delete  F8} -underline 0}
    } {
       eval .left_popup add $i
    }

    menu .right_popup -tearoff 0
    foreach i {
      {command -command {doPlot} -label {Plot selected  ENTER} -underline 0}
      {separator}
      {command -command {vectorInfo 2} -label {Info...  F3} -underline 0}
      {command -command {editVectorFilters 2} -label {Plotting options...  F4} -underline 0}
      {separator}
      {command -command {replaceInTitles 2} -label {Find+Replace in titles...} -underline 5}
      {separator}
      {command -command {moveVectors 2 1} -label {Move  F5} -underline 0}
      {command -command {copyVectors 2 1} -label {Copy  F6} -underline 0}
      {command -command {dupVectors 2} -label {Duplicate} -underline 1}
      {command -command {delVectors 2} -label {Delete  F8} -underline 0}
    } {
       eval .right_popup add $i
    }

    #
    # Bindings
    #
    bind .            <1>           {.left_popup unpost; .right_popup unpost}
    bind .            <Escape>      {.left_popup unpost; .right_popup unpost}
    bind $g(listbox1) <Any-Key>     {after 1 {status 1}}
    bind $g(listbox1) <Any-ButtonRelease>  {status 1}
    bind $g(listbox1) <Tab>         {after 1 {focus $g(listbox2)}}
    bind $g(listbox1) <Return>      {moveOrCopyVectors 1 2}
    bind $g(listbox1) <Delete>      {delVectors 1}
    bind $g(listbox1) *             {invertSelection 1}
    bind $g(listbox1) +             {selectVectors 1}
    bind $g(listbox1) <KP_Multiply> {invertSelection 1}
    bind $g(listbox1) <KP_Add>      {selectVectors 1}
    bind $g(listbox1) <F3>          {vectorInfo 1}
    bind $g(listbox1) <F4>          {editVectorFilters 1}
    bind $g(listbox1) <F5>          {copyVectors 1 2}
    bind $g(listbox1) <F6>          {moveVectors 1 2}
    bind $g(listbox1) <F8>          {delVectors 1}
    bind $g(listbox1) <1>           {focus $g(listbox1)}
    bind $g(listbox1) <Double-1>    {focus $g(listbox1); moveOrCopyVectors 1 2}
    bind $g(listbox1) <3>           {focus $g(listbox1); $g(listbox1) activate @%x,%y; .left_popup post %X %Y}

    bind $g(listbox2) <Any-Key>     {after 1 {status 2}}
    bind $g(listbox2) <Any-ButtonRelease>  {status 2}
    bind $g(listbox2) <Return>      {doPlot}
    bind $g(listbox2) <Tab>         {after 1 {focus $g(listbox1)}}
    bind $g(listbox2) <Delete>      {delVectors 2}
    bind $g(listbox2) *             {invertSelection 2}
    bind $g(listbox2) +             {selectVectors 2}
    bind $g(listbox2) <KP_Multiply> {invertSelection 2}
    bind $g(listbox2) <KP_Add>      {selectVectors 2}
    bind $g(listbox2) <F3>          {vectorInfo 2}
    bind $g(listbox2) <F4>          {editVectorFilters 2}
    bind $g(listbox2) <F5>          {copyVectors 2 1}
    bind $g(listbox2) <F6>          {moveVectors 2 1}
    bind $g(listbox2) <F8>          {delVectors 2}
    bind $g(listbox2) <1>           {focus $g(listbox2)}
    bind $g(listbox2) <Double-1>    {focus $g(listbox2); doPlot}
    bind $g(listbox2) <3>           {focus $g(listbox2); .right_popup post %X %Y}

    status 1
    status 2
    focus $g(listbox1)
}

proc createMainWindow {{geom ""}} {

    global g tcl_version


    set w .
    wm focusmodel $w passive
    if {$geom != ""} {wm geometry $w $geom} else {wm geometry $w "640x360"}
    wm maxsize $w 1009 738
    wm minsize $w 1 1
    wm overrideredirect $w 0
    wm resizable $w 1 1
    wm deiconify .
    wm protocol $w WM_DELETE_WINDOW "fileExit"

    wm title . "Plove"


    #################################
    # menu
    #################################
    if {$tcl_version < 8.0} {
        frame .menubar -borderwidth 1 -height 30 -relief raised -width 30
        createMenubar .menubar
        pack .menubar -expand 0 -fill x -side top
    } else {
        menu .menubar
        createMenubar .menubar
        . config -menu .menubar
    }

    ##########################################
    # status bar
    ##########################################
    frame .statusbar
    label .statusbar.label -relief flat -text {Ready}
    pack .statusbar.label -anchor w -expand 0 -fill none -side top
    pack .statusbar -expand 0 -fill x -side bottom

    set g(status) .statusbar.label

    ##########################################
    # main window
    ##########################################
    frame .main -borderwidth 1 -height 30 -relief sunken -width 30
    createMainArea .main
    pack .main -expand 1 -fill both
}

#===================================================================
#    STARTUP PROCEDURES
#===================================================================

proc defaultBindings {} {
   global fonts tcl_platform

   set fonts(normal) -Adobe-Helvetica-Medium-R-Normal-*-*-120-*-*-*-*-*-*
   set fonts(bold)   -Adobe-Helvetica-Bold-R-Normal-*-*-120-*-*-*-*-*-*
   #set fonts(normal) -Adobe-Helvetica-Medium-R-Normal-*-*-140-*-*-*-*-*-*
   #set fonts(bold)   -Adobe-Helvetica-Bold-R-Normal-*-*-140-*-*-*-*-*-*

   if {$tcl_platform(platform) == "unix"} {
       option add *Scrollbar.width  12
       option add *Menubutton.font  $fonts(normal)
       option add *Menu.font        $fonts(normal)
       option add *Label.font       $fonts(normal)
       option add *Entry.font       $fonts(normal)
       option add *Listbox.font     $fonts(normal)
       option add *Text.font        $fonts(normal)
       option add *Button.font      $fonts(bold)
   }

   bind Button <Return> {tkButtonInvoke %W}

}

proc checkVersion {} {

   global tcl_version

   catch {package require Unsafe} ; #for running in Netscape
   catch {package require Tk}     ; #for dynamic loading tk
   if {$tcl_version < 7.6} {
      wm deiconify .
      wm title . "Bad news..."
      frame .f
      pack .f -expand 1 -fill both -padx 2 -pady 2
      label .f.l1 -text "Your version of Tcl/Tk is too old!"
      label .f.l2 -text "Tcl7.6 and Tk4.2 or later required."
      button .f.b -text "OK" -command {exit}
      pack .f.l1 .f.l2 -side top -padx 5
      pack .f.b -side top -pady 5
      focus .f.b
      wm protocol . WM_DELETE_WINDOW {exit}
      tkwait variable ok
   }
}

#===================================================================
#    MAIN PROGRAM
#===================================================================

proc startPlove {argv} {
   global config
   global OMNETPP_PLOVE_DIR

   checkVersion
   defaultBindings
   initFilters
   createMainWindow

   set origconfigfile $config(configfile)
   set defaultconfigfile [file join $OMNETPP_PLOVE_DIR .ploverc]
   if [file readable $defaultconfigfile] {
       loadConfig $defaultconfigfile
   }
   set config(configfile) $origconfigfile
   if [file readable $config(configfile)] {
       loadConfig $config(configfile)
   }

   foreach f $argv {
       loadVectorFile $f
   }
}

