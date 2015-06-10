//==========================================================================
//  RUNSELECTIONDIALOG.H - part of
//
//                     OMNeT++/OMNEST
//            Discrete System Simulation in C++
//
//==========================================================================

/*--------------------------------------------------------------*
  Copyright (C) 1992-2015 Andras Varga
  Copyright (C) 2006-2015 OpenSim Ltd.

  This file is distributed WITHOUT ANY WARRANTY. See the file
  `license' for details on this and other legal matters.
*--------------------------------------------------------------*/

#ifndef RUNSELECTIONDIALOG_H
#define RUNSELECTIONDIALOG_H

#include <QDialog>
#include <map>

namespace qtenv {
class Qtenv;
}

namespace Ui {
class RunSelectionDialog;
}

class RunSelectionDialog : public QDialog
{
    Q_OBJECT

public:
    explicit RunSelectionDialog(qtenv::Qtenv *env, QWidget *parent = 0);
    ~RunSelectionDialog();

    std::string getConfigName();
    int getRunNumber();

private:
    Ui::RunSelectionDialog *ui;
    qtenv::Qtenv *env;

    std::vector<std::string> groupAndSortConfigNames();
};

#endif // RUNSELECTIONDIALOG_H