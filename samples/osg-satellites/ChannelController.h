//
// This file is part of an OMNeT++/OMNEST simulation example.
//
// Copyright (C) 2010 OpenSim Ltd.
//
// This file is distributed WITHOUT ANY WARRANTY. See the file
// `license' for details on this and other legal matters.
//

#ifndef __CHANNELCONTROLLER_H_
#define __CHANNELCONTROLLER_H_

#include <osg/Node>
#include <osgEarth/MapNode>
#include <osgEarthAnnotation/FeatureNode>
#include <osgEarthAnnotation/LocalGeometryNode>
#include <osgEarthUtil/LineOfSight>
#include <osgEarthUtil/LinearLineOfSight>
#include <osgEarthSymbology/Style>
#include <osgEarthSymbology/Geometry>
#include <osgEarthFeatures/Feature>

#include <omnetpp.h>
#include "OsgEarthScene.h"
#include "GroundStation.h"
#include "Satellite.h"

USING_NAMESPACE

/**
 * This module is responsible for tracking the distance of mobile nodes
 * and visualizing the connectivity graph using OSG nodes.
 */
class ChannelController : public cSimpleModule
{
protected:

    static osg::ref_ptr<osg::ShapeDrawable> createCylinderBetweenPoints(osg::Vec3 start, osg::Vec3 end, float radius, osg::Vec4 color);

    static ChannelController *instance;
    std::vector<Satellite *> satellites;
    std::vector<GroundStation *> stations;

    std::vector<osgEarth::Util::LinearLineOfSightNode *> losNodes;
    std::map<Satellite *, osg::Geometry *> orbitsMap;

    osg::ref_ptr<osg::Geode> connections = nullptr;

    bool showConnections = true;
    std::string connectionColor;
    // the node containing the osgEarth data
    osg::Group *scene = nullptr;

    virtual void initialize(int stage) override;
    virtual int numInitStages() const override { return 3; }
    virtual void handleMessage(cMessage *msg) override;
    int findSatellite(Satellite *p);
    int findGroundStation(GroundStation *p);

    void addLineOfSight(osg::Node *a, osg::Node *b, int type);

  public:
    ChannelController();
    virtual ~ChannelController();
    static ChannelController *getInstance();
    virtual void addSatellite(Satellite *p);
    virtual void removeSatellite(Satellite *p);

    virtual void addGroundStation(GroundStation *p);
    virtual void removeGroundStation(GroundStation *p);
    virtual void updateConnectionGraph();
};

#endif
