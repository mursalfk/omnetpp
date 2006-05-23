package org.omnetpp.ned.editor.graph.model.commands;

import java.util.HashMap;
import java.util.LinkedList;
import java.util.List;
import java.util.Map;

import org.eclipse.draw2d.geometry.Rectangle;
import org.eclipse.gef.commands.Command;
import org.omnetpp.ned2.model.CompoundModuleNodeEx;
import org.omnetpp.ned2.model.ConnectionNodeEx;
import org.omnetpp.ned2.model.ISubmoduleContainer;
import org.omnetpp.ned2.model.INamedGraphNode;
import org.omnetpp.ned2.model.NEDElement;
import org.omnetpp.ned2.model.pojo.ConnectionsNode;

/**
 * Clones a set of modules (copy operation)
 * @author rhornig
 *
 */
public class CloneCommand extends Command {

    private List<INamedGraphNode> modules, newModules;
    private List<ConnectionNodeEx> newConnections;
    private ISubmoduleContainer parent;
    private Map<INamedGraphNode, Rectangle> bounds;
    private Map<INamedGraphNode, Integer> indices;
    private Map<INamedGraphNode, INamedGraphNode> old2newMapping;

    public CloneCommand() {
        super("Clone");
        modules = new LinkedList<INamedGraphNode> ();
    }

    public void addModule(INamedGraphNode mod, Rectangle newBounds) {
        modules.add(mod);
        if (bounds == null) {
            bounds = new HashMap<INamedGraphNode, Rectangle>();
        }
        bounds.put(mod, newBounds);
    }

    public void addModule(INamedGraphNode mod, int index) {
        modules.add(mod);
        if (indices == null) {
            indices = new HashMap<INamedGraphNode, Integer>();
        }
        indices.put(mod, index);
    }

    /**
     * Clone the provided connection
     * @param oldConn
     */
    protected ConnectionNodeEx cloneConnection(ConnectionNodeEx oldConn, INamedGraphNode srcModuleRef, INamedGraphNode destModuleRef) {
            
        ConnectionsNode connectionParent = null;
        if (parent instanceof CompoundModuleNodeEx)
            connectionParent = ((CompoundModuleNodeEx)parent).getFirstConnectionsChild();
        
        ConnectionNodeEx newConn = (ConnectionNodeEx)oldConn.deepDup(null);
            
        connectionParent.appendChild(newConn);
        newConn.setSrcModuleRef(srcModuleRef);
        newConn.setDestModuleRef(destModuleRef);

        newConnections.add(newConn);

        return newConn;
    }
    
    protected INamedGraphNode cloneModule(INamedGraphNode oldModule, Rectangle newBounds, int index) {
    	INamedGraphNode newModule = null;

        // duplicate the subtree but do not add to the new parent yet
        newModule = (INamedGraphNode)((NEDElement)oldModule).deepDup(null);
        newModule.getDisplayString().setLocation(newBounds.getLocation());
        newModule.setName(oldModule.getName()+"_copy");

        if (index < 0) {
            parent.addSubmodule(newModule);
        } else {
            parent.insertSubmodule(index, newModule);
        }

        // keep track of the new modules so we can delete them in undo
        newModules.add(newModule);
        
        // keep track of the newModule -> OldModule map so that we can properly
        // attach all connections later.
        old2newMapping.put(oldModule, newModule);
        
        return newModule;
    }

    @Override
    public void execute() {
        redo();
    }

    public void setParent(ISubmoduleContainer parent) {
        this.parent = parent;
    }

    @Override
    public void redo() {
        old2newMapping = new HashMap<INamedGraphNode, INamedGraphNode>();
        newConnections = new LinkedList<ConnectionNodeEx>();
        newModules = new LinkedList<INamedGraphNode>();

        for (INamedGraphNode mod : modules){
            if (bounds != null && bounds.containsKey(mod)) {
                cloneModule(mod, bounds.get(mod), -1);
            } else if (indices != null && indices.containsKey(mod)) {
                cloneModule(mod, null, indices.get(mod));
            } else {
                cloneModule(mod, null, -1);
            }
        }

        // go through all modules that were previously cloned and check all the source connections
        for (INamedGraphNode oldSrcMod : modules)
            for (ConnectionNodeEx oldConn : oldSrcMod.getSrcConnections()) {
                INamedGraphNode oldDestMod = oldConn.getDestModuleRef();
                // if the destination side was also selected clone this connection connection too 
                // TODO future: clone the connections ONLY if they are selected too
                if (old2newMapping.containsKey(oldDestMod)) {
                    INamedGraphNode newSrcMod = old2newMapping.get(oldSrcMod);
                    INamedGraphNode newDestMod = old2newMapping.get(oldDestMod);
                    cloneConnection(oldConn, newSrcMod, newDestMod);
                }
            }
    }

    @Override
    public void undo() {
        for (INamedGraphNode mod : newModules)
            mod.removeFromParent();
        
        for (ConnectionNodeEx conn : newConnections)
            conn.removeFromParent();
        
    }

}