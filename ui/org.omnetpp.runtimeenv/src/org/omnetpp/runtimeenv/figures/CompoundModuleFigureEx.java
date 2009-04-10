package org.omnetpp.runtimeenv.figures;

import org.eclipse.draw2d.LineBorder;
import org.eclipse.draw2d.geometry.Dimension;
import org.eclipse.swt.SWT;
import org.omnetpp.figures.CompoundModuleFigure;
import org.omnetpp.runtimeenv.editors.IInspectorFigure;
import org.omnetpp.runtimeenv.editors.IInspectorPart;

//FIXME draw proper resize handles, and make the mouse listener recognize it
public class CompoundModuleFigureEx extends CompoundModuleFigure implements IInspectorFigure {
    protected IInspectorPart inspectorPart;

    public CompoundModuleFigureEx() {
        setMinimumSize(new Dimension(20,20));
        setBorder(new LineBorder(2));
    }

    public void setDragHandlesShown(boolean b) {
        setBorder(b ? new LineBorder(4) : new LineBorder(2)); //XXX for now
    }

    public boolean getDragHandlesShown() {
        return ((LineBorder)getBorder()).getWidth()==4; //XXX for now
    }

    public IInspectorPart getInspectorPart() {
        return inspectorPart;
    }

    public void setInspectorPart(IInspectorPart inspectorPart) {
        this.inspectorPart = inspectorPart;
    }

    @Override
    public int getDragOperation(int x, int y) {
        //TODO properly detect resize handles
        int result = 0;
        if (Math.abs(getBounds().x - x) < 5) result |= SWT.LEFT;
        if (Math.abs(getBounds().y - y) < 5)  result |= SWT.TOP;
        if (Math.abs(getBounds().right() - x) < 5) result |= SWT.RIGHT;
        if (Math.abs(getBounds().bottom() - y) < 5) result |= SWT.BOTTOM;
        if (result==0) result = SWT.LEFT|SWT.TOP|SWT.RIGHT|SWT.BOTTOM;
        return result;
    }
}
