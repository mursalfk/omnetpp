//==========================================================================
//  TKLIB.CC -
//	      for the Tcl/Tk windowing environment of
//			      OMNeT++
//==========================================================================

/*--------------------------------------------------------------*
  Copyright (C) 1992,99 Andras Varga
  Technical University of Budapest, Dept. of Telecommunications,
  Stoczek u.2, H-1111 Budapest, Hungary.

  This file is distributed WITHOUT ANY WARRANTY. See the file
  `license' for details on this and other legal matters.
*--------------------------------------------------------------*/

#include <stdio.h>
#include <string.h>
#include <time.h>
#include <assert.h>
#include <tk.h>

#include "cobject.h"
#include "cmodule.h"
#include "csimul.h"
#include "tklib.h"
#include "tkinsp.h"
#include "tkapp.h"
#include "patmatch.h"

//=======================================================================

bool memoryIsLow()
{
    return 0;
}

char *ptrToStr( void *ptr, char *buffer)
{
    static char staticbuf[20];
    if (buffer==NULL)
	   buffer = staticbuf;

    if (ptr==0)
	   strcpy(buffer,"ptr0");  // GNU C++'s sprintf() says "nil"
    else
	   sprintf(buffer,"ptr%p", ptr );
    return buffer;
}

void *strToPtr( char *s )
{
    void *ptr;
    sscanf(s+3,"%p",&ptr);
    return ptr;
}

//-----------------------------------------------------------------------

//
// setTypes():
//   Called by inspector() funcs of classes, if they get -1 as type.
//   The func. places the inspector types supported by the class
//   into the array passed, terminated by -1.
//   The default inspector should be the first item.
//

void setTypes(void *data, ...)
{
   int *p = (int *)data;

   int t;
   va_list va;
   va_start(va,data);
   do {
      t = va_arg(va,int);
      *p++ = t;
   } while (t>=0);
}

//-----------------------------------------------------------------------

static bool do_fill_listbox( cObject *obj, bool beg, Tcl_Interp *intrp, char *lstbox, InfoFunc f, bool dp)
{
    static char *listbox;
    static Tcl_Interp *interp;
    static InfoFunc infofunc;
    static bool deep;
    static int ctr;
    if (!obj) {       // setup
	 listbox = lstbox;
	 interp = intrp;
	 infofunc = f;
	 deep = dp;
	 ctr  = 0;
	 return FALSE;
    }
    if( !beg ) return FALSE;
    if( (deep || ctr>0) && !memoryIsLow() ) // if deep=FALSE, exclude owner object
    {
	 CHK(Tcl_VarEval(interp, listbox," insert end {",infofunc(obj),"}",NULL));
    }
    return deep || ctr++ == 0;
}

void collection( cObject *object, Tcl_Interp *interp, char *listbox, InfoFunc infofunc, bool deep)
{
    // feeds all children of 'object' into the listbox
    // CHK(Tcl_VarEval(interp, listbox, " delete 0 end", NULL ));
    do_fill_listbox(NULL,FALSE, interp, listbox, infofunc, deep);
    object->forEach( (ForeachFunc)do_fill_listbox );
}

static void _modcollection(cModule *parent, Tcl_Interp *interp, char *listbox, InfoFunc infofunc, bool simpleonly, bool deep )
{
    // loop through module vector
    for( int i=1; i<=simulation.lastModuleIndex() && !memoryIsLow(); i++ )
    {
      cModule *mod = simulation.module(i);
      if (mod && mod!=simulation.systemModule() && mod->parentModule()==parent)
      {
	 if (!simpleonly || mod->isSimple())
	    CHK(Tcl_VarEval(interp, listbox," insert end {",infofunc(mod),"}",NULL));

	 // handle 'deep' option using recursivity
	 if (deep)
	    _modcollection(mod,interp,listbox,infofunc,simpleonly,deep);
      }
    }
}

void modcollection(cModule *parent, Tcl_Interp *interp, char *listbox, InfoFunc infofunc, bool simpleonly, bool deep )
{
    // CHK(Tcl_VarEval(interp, listbox, " delete 0 end", NULL ));
    if (deep)
    {
	 if (!simpleonly || parent->isSimple())
	    CHK(Tcl_VarEval(interp, listbox," insert end {",infofunc(parent),"}",NULL));
    }
    _modcollection(parent,interp,listbox,infofunc,simpleonly,deep);
}

//-----------------------------------------------------------------------

char *printptr(cObject *object, char *buf)
{
    // produces string like: "ptr80004e1f  ".
    // returns a pointer to terminating '\0' char
    ptrToStr(object, buf);
    char *s = buf+strlen(buf);
    s[0]=' '; s[1]=' '; s[2]='\0'; // append two spaces
    return s+2;
}

char *infofunc_nameonly( cObject *object)
{
    static char buf[128];
    char *d = printptr(object,buf);
    const char *s = object->fullName();
    strcpy(d, (s && s[0]) ? s : "<noname>" );
    return buf;
}

char *infofunc_infotext( cObject *object)
{
    static char buf[128];
    char *d = printptr(object,buf);
    object->info( d );
    return buf;
}

char *infofunc_fullpath( cObject *object)
{
    static char buf[128];
    char *d = printptr(object,buf);
    const char *s = object->fullPath();
    strcpy(d, (s && s[0]) ? s : "<noname>" );
    return buf;
}

char *infofunc_typeandfullpath( cObject *object)
{
    static char buf[128];
    char *d = printptr(object,buf);
    const char *clname = object->className();
    const char *path = object->fullPath();
    int padding = 16-strlen(clname); if (padding<1) padding=1;
    sprintf(d, "(%s)%*s %.80s", clname, padding,"", path );
    return buf;
}

char *infofunc_module( cObject *object)
{
    static char buf[128];
    char *d = printptr(object,buf);
    cModule *mod = (cModule *)object;
    const char *path = mod->fullPath();
    const char *clname = mod->className();
    int padding = 16-strlen(clname); if (padding<1) padding=1;
    sprintf(d, "#%-3d (%s)%*s %.80s", mod->id(), clname, padding,"", path);
    return buf;
}

//----------------------------------------------------------------------

static int inspmatch_ctr;
static bool do_inspect_matching( cObject *obj, bool beg, short *patt, int typ, bool co)
{
    static bool deep;
    static bool countonly;
    static short *pattern;
    static int type;
    static int ctr;
    if (!obj) {       // setup
	 pattern = patt;
	 type = typ;
	 deep = TRUE;
	 countonly=co;
	 ctr  = 0;
	 return FALSE;
    }
    if( !beg ) return FALSE;
    if( (deep || ctr>0) && !memoryIsLow() ) // if deep=FALSE, exclude owner object
    {
	 const char *fullpath = obj->fullPath();
	 if (stringmatch(pattern,fullpath))
	 {
	   if (!countonly)
	       ((TOmnetTkApp *)(ev.app))->inspect(obj,type,NULL);
	   inspmatch_ctr++;
	 }
    }
    return deep || ctr++ == 0;
}

int inspect_matching(cObject *object, Tcl_Interp *, char *pattern, int type, bool countonly)
{
    // open inspectors for children of 'object' whose fullpath matches pattern
    short trf_pattern[512];
    if (transform_pattern(pattern, trf_pattern)==FALSE)
       return 0; // bad pattern: unmatched '{'
    inspmatch_ctr=0;
    do_inspect_matching(NULL,FALSE, trf_pattern, type, countonly);
    object->forEach( (ForeachFunc)do_inspect_matching );
    return inspmatch_ctr;
}

//=============== TCL/TK STUFF ==============================================

//=== the following lines come from a sample tclApp.c
/*
 * The following variable is a special hack that is needed in order for
 * Sun shared libraries to be used for Tcl.
 */
//extern int matherr();
//int *tclDummyMathPtr = (int *) matherr;

//=== Following source based on:
//  Brent Welch: Practical Programming in Tcl and Tk
//  Chapter 30: C programming and Tk; A Custom Main Program
//

int exit_omnetpp;

//static Tk_ArgvInfo argTable[] =
//  {
//    {"-display", TK_ARGV_STRING,   (char *)NULL, (char *)&display, "Display to use"},
//    {"-debug",   TK_ARGV_CONSTANT, (char *)1,    (char *)&debug,   "Set things up for gdb-style debugging"},
//    {"",	   TK_ARGV_END,},
//  };

// Procedure to handle X errors
static int XErrorProc( ClientData, XErrorEvent *errEventPtr)
{
    fprintf(stderr, "X protocol error: ");
    fprintf(stderr, "error=%d request=%d minor=%d\n",
		    errEventPtr->error_code,
		    errEventPtr->request_code,
		    errEventPtr->minor_code );
    return 0;  // claim to have handled the error
}

// initialize Tcl/Tk and return a pointer to the interpreter
Tcl_Interp *initTk(int, char **)
{
    // 1st two args: argc, argv

    // Create interpreter
    Tcl_Interp *interp = Tcl_CreateInterp();

    // Tcl/Tk args interfere with OMNeT++'s own command-line args
    //if (Tk_ParseArgv(interp, (Tk_Window)NULL, &argc, argv, argTable, 0)!=TCL_OK)
    //{
    //	  fprintf(stderr, "%s\n", interp->result);
    //	  return TCL_ERROR;
    //}

    if (Tcl_Init(interp) != TCL_OK)
    {
	fprintf(stderr, "Tcl_Init failed: %s\n", interp->result);
	return 0;
    }

    if (Tk_Init(interp) != TCL_OK)
    {
	fprintf(stderr, "Tk_Init failed: %s\n", interp->result);
	return 0;
    }

    Tcl_StaticPackage(interp, "Tk", Tk_Init, (Tcl_PackageInitProc *) NULL);

    Tk_Window mainWindow = Tk_MainWindow(interp);

    Tk_SetAppName( mainWindow, "omnetpp" );
    Tk_SetClass( mainWindow, "Omnetpp" );

    // Register X error handler and ask for synchronous protocol to help debugging
    Tk_CreateErrorHandler( Tk_Display(mainWindow), -1,-1,-1, XErrorProc, (ClientData)mainWindow );

    // Grab initial size and background
    Tk_GeometryRequest(mainWindow,200,200);

    return interp;
}

// create custom commands (implemented in tkcmd.cc) in Tcl
int createTkCommands( Tcl_Interp *interp, OmnetTclCommand *commands)
{
    for(;commands->namestr!=NULL; commands++)
    {
	Tcl_CreateCommand( interp, commands->namestr, commands->func,
			   (ClientData)NULL, (Tcl_CmdDeleteProc *)NULL);
    }
    return TCL_OK;
}

// run the Tk application
int runTk( Tcl_Interp *)
{
    // Custom event loop
    //	the C++ variable exit_omnetpp is used for exiting
    while (!exit_omnetpp)
    {
       Tk_DoOneEvent(TK_ALL_EVENTS);
    }

    return TCL_OK;
}

