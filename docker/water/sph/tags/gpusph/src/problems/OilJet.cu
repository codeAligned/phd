/*
 * OilJet.cu
 *
 *  Created on: 25 juin 2015
 *      Author: alexisherault
 */
#include <iostream>
#include <stdexcept>

#include "OilJet.h"
#include "particledefine.h"
#include "GlobalData.h"
#include "cudasimframework.cu"


OilJet::OilJet(GlobalData *_gdata) : XProblem(_gdata)
{
	// Data for problem setup
	layers = 5;

	/* SETUP_FRAMEWORK(
		kernel<WENDLAND>,
	    //viscosity<ARTVISC>,
		viscosity<KINEMATICVISC>,
		//viscosity<SPSVISC>,
		//boundary<LJ_BOUNDARY>
		//boundary<MK_BOUNDARY>
		boundary<DYN_BOUNDARY>,
		periodicity<PERIODIC_XY>
	); */

	SETUP_FRAMEWORK(
		formulation<SPH_GRENIER>,
		viscosity<DYNAMICVISC>,
		boundary<DYN_BOUNDARY>
	);

	set_deltap(0.05f);  // 0.05 is minimum to have 3 layers of particles in the cylinder

	// Water and oil level
	water_level = 2.;
	pipe_length = 2.;
	inner_diam = 0.4;

	// Size and origin of the simulation domain
	lx = 2;
	ly = 2;
	lz = water_level + pipe_length + layers*m_deltap;

	m_size = make_double3(lx , ly, 1.1*lz);
	m_origin = make_double3(0, 0, - pipe_length - layers*m_deltap);

	//addFilter(SHEPARD_FILTER, 20);
	  //MLS_FILTER

	// SPH parameters
	simparams()->dt = 0.00013;
	simparams()->dtadaptfactor = 0.2;
	simparams()->buildneibsfreq = 10;
	simparams()->tend = 2.; //seconds
	simparams()->maxneibsnum = 512;

	// Physical parameters
	physparams()->gravity = make_float3(0.0f, 0.0f, -9.81f);
	float g = length(physparams()->gravity);

	add_fluid(1000.0);
	set_equation_of_state(0,  7.0f, 10.f);
	set_kinematic_visc(0, 1.0e-6);

	physparams()->artvisccoeff =  0.3;
	physparams()->smagfactor = 0.12*0.12*m_deltap*m_deltap;
	physparams()->kspsfactor = (2.0/3.0)*0.0066*m_deltap*m_deltap;
	physparams()->epsartvisc = 0.01*simparams()->slength*simparams()->slength;

	//Wave piston definition:  location, start & stop times, stroke and frequency (2 \pi/period)
	piston_tstart = 0.0;
	piston_tend = simparams()->tend;
	piston_vel = 1.0;

	// Drawing and saving times
	add_writer(VTKWRITER, .01);  //second argument is saving time in seconds

	// Name of problem used for directory creation
	m_name = "OilJet";

	// Building the geometry
	const int layersm1 = layers - 1;
	setPositioning(PP_CORNER);

	GeometryID fluid1 = addBox(GT_FLUID, FT_SOLID,
		Point(m_deltap/2, m_deltap/2, m_deltap/2),
		lx - m_deltap, ly - m_deltap, water_level - m_deltap);

	GeometryID bottom = addBox(GT_FIXED_BOUNDARY, FT_BORDER,
		Point(m_deltap/2, m_deltap/2, -(layersm1 + 0.5)*m_deltap),
		lx - m_deltap, ly - m_deltap, layersm1*m_deltap);
	disableCollisions(bottom);

	setPositioning(PP_BOTTOM_CENTER);
	double plength = pipe_length + layersm1*m_deltap - m_deltap/2.;
	Point corigin = Point(lx/2., ly/2., - plength - m_deltap/2.);
	GeometryID pipe = addCylinder(GT_FIXED_BOUNDARY, FT_BORDER,
		corigin, (inner_diam - m_deltap)/2. + layersm1*m_deltap, plength );
	disableCollisions(pipe);

	GeometryID oil = addCylinder(GT_FLUID, FT_SOLID,
		corigin, (inner_diam - m_deltap)/2., plength);

	piston_origin = make_double3(lx/2., ly/2., - plength + layersm1*m_deltap/2.);
	GeometryID piston = addCylinder(GT_MOVING_BODY, FT_BORDER,
		corigin, (inner_diam - m_deltap)/2. + layersm1*m_deltap, layersm1*m_deltap);
	disableCollisions(piston);
}

void
OilJet::moving_bodies_callback(const uint index, Object* object, const double t0, const double t1,
		const float3& force, const float3& torque, const KinematicData& initial_kdata,
		KinematicData& kdata, double3& dx, EulerParameters& dr)
{
    dx = make_double3(0.0);
    dr.Identity();
    kdata.avel = make_double3(0.0);
    if (t0 >= piston_tstart & t1 <= piston_tend) {
    	kdata.lvel = make_double3(0.0, 0.0, piston_vel);
    	dx.z = -piston_vel*(t0 - t1);
	} else {
		kdata.lvel = make_double3(0.0);
	}
}
