//==========================================================================
//  STATINSP.H -
//            for the Tcl/Tk windowing environment of
//                            OMNeT++
//==========================================================================

/*--------------------------------------------------------------*
  Copyright (C) 1992-2002 Andras Varga
  Technical University of Budapest, Dept. of Telecommunications,
  Stoczek u.2, H-1111 Budapest, Hungary.

  This file is distributed WITHOUT ANY WARRANTY. See the file
  `license' for details on this and other legal matters.
*--------------------------------------------------------------*/

#ifndef __STATINSP_H
#define __STATINSP_H

#include <tk.h>
#include "inspector.h"
#include "omnetapp.h"


class THistogramWindow : public TInspector
{
   public:
      char canvas[64];
   public:
      THistogramWindow(cObject *obj,int typ,const char *geom,void *dat=NULL);
      virtual void createWindow();
      virtual void update();
      virtual void writeBack() {}
      virtual int inspectorCommand(Tcl_Interp *interp, int argc, char **argv);

      // return textual information in general or about a value/value pair
      void generalInfo( char *buf );
      void cellInfo( char *buf, int cellindex );
};

class CircBuffer
{
   public:
      struct CBEntry {
        simtime_t t;
        double value1, value2;
      };
      CBEntry *buf;
      int size, n, head;
   CircBuffer( int size );
   ~CircBuffer();
   void add(simtime_t t, double value1, double value2);
   int tail() {return (head-n+1+size)%size;}
};

class TOutVectorWindow : public TInspector
{
   public:
      char canvas[64];        // widget namestr
      CircBuffer circbuf;    // buffer to store values

      // configuration
      enum {DRAW_DOTS, DRAW_BARS, DRAW_PINS, DRAW_SAMPLEHOLD, DRAW_LINES, NUM_DRAWINGMODES};
      bool autoscale;
      int drawing_mode;
      double miny, maxy;
      double time_factor; // x scaling: secs/10 pixel
      double moving_tline;   // t position of moving axis

   public:
      TOutVectorWindow(cObject *obj,int typ,const char *geom,void *dat=NULL, int size=100);
      ~TOutVectorWindow();
      virtual void createWindow();
      virtual void update();
      virtual int inspectorCommand(Tcl_Interp *interp, int argc, char **argv);

      // return textual information in general or about a value/value pair
      void generalInfo( char *buf );
      void valueInfo( char *buf, int valueindex );

      // configuration get (text form) / set
      void getConfig( char *buf );
      void setConfig( double timef, double miny, double maxy, char *mode );
};

class TStatisticInspector: public TInspector
{
   public:
      TStatisticInspector(cObject *obj,int typ,const char *geom,void *dat=NULL);
      virtual void createWindow();
      virtual void update();
};

#endif


