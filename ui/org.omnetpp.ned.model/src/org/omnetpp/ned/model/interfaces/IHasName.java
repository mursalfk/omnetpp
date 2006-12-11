package org.omnetpp.ned.model.interfaces;

/**
 * @author rhornig
 * Objects that have a name property
 */
public interface IHasName {

	static String INITIAL_NAME = "unnamed";
	/**
	 * Returns name attribute 
	 */
	public String getName();

	/**
	 * Sets name attribute 
	 */
	public void setName(String name);

}