/*  Copyright 2011-2013 Alexis Herault, Giuseppe Bilotta, Robert A. Dalrymple, Eugenio Rustico, Ciro Del Negro

    Istituto Nazionale di Geofisica e Vulcanologia
        Sezione di Catania, Catania, Italy

    Università di Catania, Catania, Italy

    Johns Hopkins University, Baltimore, MD

    This file is part of GPUSPH.

    GPUSPH is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    GPUSPH is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with GPUSPH.  If not, see <http://www.gnu.org/licenses/>.
*/

#include <iostream>

#include "DamBreakGate.h"
#include "Cube.h"
#include "Point.h"
#include "Vector.h"
#include "GlobalData.h"
#include "cudasimframework.cu"

#define SIZE_X		(1.60)
#define SIZE_Y		(0.67)
#define SIZE_Z		(0.40)

// default: origin in 0,0,0
#define ORIGIN_X	(0)
#define ORIGIN_Y	(0)
#define ORIGIN_Z	(0)


DamBreakGate::DamBreakGate(GlobalData *_gdata) : XProblem(_gdata)
{
	// Size and origin of the simulation domain
	m_size = make_double3(SIZE_X, SIZE_Y, SIZE_Z + 0.7);
	m_origin = make_double3(ORIGIN_X, ORIGIN_Y, ORIGIN_Z);

	SETUP_FRAMEWORK(
		viscosity<ARTVISC>,//DYNAMICVISC//SPSVISC
		boundary<LJ_BOUNDARY>,
		add_flags<ENABLE_MOVING_BODIES>
	);

	//addFilter(MLS_FILTER, 10);

	// SPH parameters
	set_deltap(0.015f);
	simparams()->dt = 0.0001f;
	simparams()->dtadaptfactor = 0.3;
	simparams()->buildneibsfreq = 10;
	simparams()->tend = 10.f;

	// Physical parameters
	H = 0.4f;
	physparams()->gravity = make_float3(0.0, 0.0, -9.81f);
	float g = length(physparams()->gravity);
	add_fluid(1000.0);
	set_equation_of_state(0,  7.0f, 20.f);

    //set p1coeff,p2coeff, epsxsph here if different from 12.,6., 0.5
	physparams()->dcoeff = 5.0f*g*H;
	physparams()->r0 = m_deltap;

	// BC when using MK boundary condition: Coupled with m_simsparams->boundarytype=MK_BOUNDARY
	#define MK_par 2
	physparams()->MK_K = g*H;
	physparams()->MK_d = 1.1*m_deltap/MK_par;
	physparams()->MK_beta = MK_par;
	#undef MK_par

	set_kinematic_visc(0, 1.0e-6f);
	physparams()->artvisccoeff = 0.3f;
	physparams()->epsartvisc = 0.01*simparams()->slength*simparams()->slength;

	// Drawing and saving times
	add_writer(VTKWRITER, 0.1);
	add_writer(COMMONWRITER, 0.0);

	// Name of problem used for directory creation
	m_name = "DamBreakGate";

	// Building the geometry
	float r0 = physparams()->r0;
	setPositioning(PP_CORNER);

	GeometryID experiment_box = addBox(GT_FIXED_BOUNDARY, FT_BORDER,
		Point(ORIGIN_X, ORIGIN_Y, ORIGIN_Z), 1.6, 0.67, 0.4);
	disableCollisions(experiment_box);
	GeometryID unfill_top = addBox(GT_FIXED_BOUNDARY, FT_NOFILL,
		Point(ORIGIN_X, ORIGIN_Y, ORIGIN_Z+0.4), 1.6, 0.67, 0.1);
	disableCollisions(unfill_top);
	setEraseOperation(unfill_top, ET_ERASE_BOUNDARY);

	float3 gate_origin = make_float3(0.4 + 2*r0, r0, r0);
	GeometryID gate = addBox(GT_MOVING_BODY, FT_BORDER,
		Point(gate_origin) + Point(ORIGIN_X, ORIGIN_Y, ORIGIN_Z), 0, 0.67-2*r0, 0.4);
	disableCollisions(gate);

	GeometryID obstacle = addBox(GT_FIXED_BOUNDARY, FT_BORDER,
		Point(0.9 + ORIGIN_X, 0.24 + ORIGIN_Y, r0 + ORIGIN_Z), 0.12, 0.12, 0.4 - r0);
	disableCollisions(obstacle);

	GeometryID fluid = addBox(GT_FLUID, FT_SOLID,
		Point(r0 + ORIGIN_X, r0 + ORIGIN_Y, r0 + ORIGIN_Z), 0.4, 0.67 - 2*r0, 0.4 - r0);

	bool wet = false;	// set wet to true have a wet bed experiment
	if (wet) {

		GeometryID fluid1 = addBox(GT_FLUID, FT_SOLID,
			Point(0.4 + 3*r0 + ORIGIN_X, r0 + ORIGIN_Y, r0 + ORIGIN_Z),
			0.5 - 4*r0, 0.67 - 2*r0, 0.03);

		GeometryID fluid2 = addBox(GT_FLUID, FT_SOLID,
			Point(1.02 + r0  + ORIGIN_X, r0 + ORIGIN_Y, r0 + ORIGIN_Z),
			0.58 - 2*r0, 0.67 - 2*r0, 0.03);

		GeometryID fluid3 = addBox(GT_FLUID, FT_SOLID,
			Point(0.9 + ORIGIN_X , m_deltap  + ORIGIN_Y, r0 + ORIGIN_Z),
			0.12, 0.24 - 2*r0, 0.03);

		GeometryID fluid4 = addBox(GT_FLUID, FT_SOLID,
			Point(0.9 + ORIGIN_X , 0.36 + m_deltap  + ORIGIN_Y, r0 + ORIGIN_Z),
			0.12, 0.31 - 2*r0, 0.03);
	}

}

void
DamBreakGate::moving_bodies_callback(const uint index, Object* object, const double t0, const double t1,
			const float3& force, const float3& torque, const KinematicData& initial_kdata,
			KinematicData& kdata, double3& dx, EulerParameters& dr)
{
	const double tstart = 0.1;
	const double tend = 0.4;

	// Computing, at t = t1, new position of center of rotation (here only translation)
	// along with linear velocity
	if (t1 >= tstart && t1 <= tend) {
		kdata.lvel = make_double3(0.0, 0.0, 4.*(t1 - tstart));
		kdata.crot.z = initial_kdata.crot.z + 2.*(t1 - tstart)*(t1 - tstart);
		}
	else
		kdata.lvel = make_double3(0.0f);

	// Computing the displacement of center of rotation between t = t0 and t = t1
	double ti = min(tend, max(tstart, t0));
	double tf = min(tend, max(tstart, t1));
	dx.z = 2.*(tf - tstart)*(tf - tstart) - 2.*(ti - tstart)*(ti - tstart);

	// Setting angular velocity at t = t1 and the rotation between t = t0 and t = 1.
	// Here we have a simple translation movement so the angular velocity is null and
	// the rotation between t0 and t1 equal to identity.
	kdata.avel = make_double3(0.0f);
	dr.Identity();
}


