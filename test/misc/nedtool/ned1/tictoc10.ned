//
// This file is part of an OMNeT++/OMNEST simulation example.
//
// Copyright (C) 2003-2015 Andras Varga
//
// This file is distributed WITHOUT ANY WARRANTY. See the file
// `license' for details on this and other legal matters.
//


simple Txc10
    gates:
        in: in[];
        out: out[];
endsimple

//
// Same as Tictoc9.
//
module Tictoc10
    submodules:
        tic: Txc10[6];   // we'll have 6 Txc modules
            display: "i=block/process";
    connections:
        tic[0].out++ --> delay 100ms --> tic[1].in++;
        tic[0].in++ <-- delay 100ms <-- tic[1].out++;

        tic[1].out++ --> delay 100ms --> tic[2].in++;
        tic[1].in++ <-- delay 100ms <-- tic[2].out++;

        tic[1].out++ --> delay 100ms --> tic[4].in++;
        tic[1].in++ <-- delay 100ms <-- tic[4].out++;

        tic[3].out++ --> delay 100ms --> tic[4].in++;
        tic[3].in++ <-- delay 100ms <-- tic[4].out++;

        tic[4].out++ --> delay 100ms --> tic[5].in++;
        tic[4].in++ <-- delay 100ms <-- tic[5].out++;
endmodule

network tictoc10 : Tictoc10
endnetwork

