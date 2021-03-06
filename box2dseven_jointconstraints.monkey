' box2dseven.monkey
' F1 - reset
' F2 - add ball

Strict

Import mojo
Import box2d.collision

Const WORLDSCALE#=1.0/8
Const TIMESTEP#=1.0/20			'frantic 2x clock
Const FRAMERATE%=30
Const SPEEDLOOPS%=20
Const POSLOOPS%=20

Const SAHeight%=1850,SAChin%=1640
Const SAHeadRadius%=(SAHeight-SAChin)/2
Const SAHeadPosition%=SAHeight-SAHeadRadius
Global SAMetrics%[]=[
	0,SAHeadPosition,SAHeadRadius,
	0,1650,50,
	0,1400,50,
	0,1250,40,
	0,1000,80,
	0,840,30,
	0,660,5,
	20,560,30,
	-20,120,20,
	200,60,10]

Class Body
	Global BodyDef:=New b2BodyDef()
	Global FixtureDef:=New b2FixtureDef()
	Global Impulse:=New b2Vec2

	Field parent:b2World
	Field body:b2Body
	Field density#=1
	
	Method New(	world:b2World,x#,y#,bodytype%)
		BodyDef.type = bodytype
		BodyDef.fixedRotation=False
		BodyDef.position.Set(x*WORLDSCALE,y*WORLDSCALE)
		body=world.CreateBody(BodyDef)
		parent=world
	End

	Method AddRadialFixture:b2Fixture(x#,y#,r#,bits%,mask%)
		Local shape:=New b2CircleShape(r*WORLDSCALE)
		If x Or y shape.SetLocalPosition New b2Vec2(x*WORLDSCALE,y*WORLDSCALE)
		Local fixture:=AddFixture(shape,bits,mask)
		fixture.SetRestitution(.6)
		fixture.SetFriction(.8)
		Return fixture
	End
	
	Method AddSquareFixture:b2Fixture(w#,h#,bits%,mask%)
		Local shape:=New b2PolygonShape
		shape.SetAsBox w*WORLDSCALE,h*WORLDSCALE
		Return AddFixture(shape,bits,mask)
	End
	
	Method AddPathFixture:Void(points#[],bits%,mask%)
		Local n%=points.Length/3
		For Local i%=0 Until n
			Local x#=points[i*3+0]
			Local y#=points[i*3+1]
			Local r#=points[i*3+2]
			AddRadialFixture x,y,r,bits,mask
		Next

		For Local i%=0 Until n-1
			Local x0#=points[i*3+0]*WORLDSCALE
			Local y0#=points[i*3+1]*WORLDSCALE
			Local r0#=points[i*3+2]*WORLDSCALE
			Local x1#=points[i*3+3]*WORLDSCALE
			Local y1#=points[i*3+4]*WORLDSCALE
			Local r1#=points[i*3+5]*WORLDSCALE
			Local dx#=x1-x0
			Local dy#=y1-y0
			Local dd#=dx*dx+dy*dy
			Local d#=Sqrt(dd)
			Local tx#=dy/d
			Local ty#=-dx/d
			Local pts:b2Vec2[4]
			pts[0]=New b2Vec2(x0+r0*tx, y0+r0*ty)
			pts[1]=New b2Vec2(x1+r1*tx, y1+r1*ty)
			pts[2]=New b2Vec2(x1-r1*tx, y1-r1*ty)
			pts[3]=New b2Vec2(x0-r0*tx, y0-r0*ty)
			Local shape:=New b2PolygonShape
			shape.SetAsArray pts,4
			AddFixture(shape,bits,mask)
		Next
	End

	' must be convex
	
	Method AddPolygonFixture:b2Fixture(pts#[],bits%,mask%)
		Local shape:=New b2PolygonShape
		Local n%=pts.Length()/2
		Local points:=New 	b2Vec2[n]
		For Local i%=0 Until n
			Local x#=pts[i*2+0]
			Local y#=pts[i*2+1]
			points[i]=New b2Vec2(x,y)
		Next
		shape.SetAsArray points,n
		Return AddFixture(shape,bits,mask)
	End
	
	' complex geometry welcome, only attach to static bodies as edges have zero mass
		
	Method AddStaticEdge:Void(pts#[],bits%,mask%)
		Local last%=pts.Length()/2-1
		Local x1#=pts[last*2+0]
		Local y1#=pts[last*2+1]
		For Local i%=0 Until last
			Local x0#=x1
			Local y0#=y1
			x1=pts[i*2+0]
			y1=pts[i*2+1]
			Local p0:=New b2Vec2(x0,y0)
			Local p1:=New b2Vec2(x1,y1)
			Local shape:=New b2PolygonShape
			shape.SetAsEdge p0,p1
			AddFixture(shape,bits,mask)
		Next

	End
	
	Method AddFixture:b2Fixture(shape:b2Shape,bits%,mask%)
		FixtureDef.shape=shape
		FixtureDef.density=density
		FixtureDef.filter.categoryBits=bits
		FixtureDef.filter.maskBits=mask
		Local fixture:=body.CreateFixture(FixtureDef)
		Return fixture
	End
	
	Method ApplyImpulse:Void(x#,y#)
		Impulse.x=x
		Impulse.y=y
		body.ApplyForce Impulse,body.GetPosition()
	End
		
	Method ApplyTorque:Void(t#)
		body.ApplyTorque t
	End

	Method Rotate:Void(degrees#)
		body.SetAngle body.GetAngle()+degrees*PI/180
	End

End

Class Sim

	Field gravity:b2Vec2
	Field world:b2World
	
	Method New(gravityx#,gravityy#)
		gravity=New b2Vec2(gravityx,gravityy)
		Init gravity
	End

	Method Init:Void(gravity:b2Vec2)
		world = New b2World(gravity,True)	'gravity,dosleep
		world.SetWarmStarting(True)
		Local dbgDraw:=New DebugDraw()
		dbgDraw.SetDrawScale(1.0/WORLDSCALE)
		dbgDraw.SetFillAlpha(1.0)
		dbgDraw.SetLineThickness(1.0)
		dbgDraw.SetFlags(b2DebugDraw.e_shapeBit | b2DebugDraw.e_jointBit)'| b2DebugDraw.e_pairBit)
		world.SetDebugDraw(dbgDraw)
	End
			
	Method CreateBody:Body(x#,y#)
		Return New Body(world,x,y,b2Body.b2_Body)
	End
	
	Method CreateStatic:Body(x#,y#)
		Return New Body(world,x,y,b2Body.b2_staticBody)
	End

	Method CreateRevolute:b2RevoluteJoint(a:Body,b:Body,rad0#,rad1#)
		Local r:=New b2RevoluteJointDef
		Local p:=b.body.GetPosition()
		r.Initialize(a.body,b.body,p)
		r.maxMotorTorque = 2000
		r.motorSpeed = 0
		If rad0 Or rad1 r.enableLimit = True
		r.enableMotor = True
		r.lowerAngle=rad0
		r.upperAngle=rad1
		Local joint:=world.CreateJoint(r)
		Return b2RevoluteJoint(joint)
	End
	
	Method CreatePrism:b2PrismaticJoint(a:Body,px#,py#,b:Body,ax#,ay#,force#,speed#)

		Local pdef:=New b2PrismaticJointDef()

		Local axis:=New b2Vec2(ax,ay)

		Local p:=New b2Vec2(px*WORLDSCALE,py*WORLDSCALE)

		'		Local p:=b.body.GetPosition()

		pdef.Initialize a.body,b.body,p,axis

		pdef.lowerTranslation = -0.2
		pdef.upperTranslation = 0.6
		pdef.enableLimit = True

		pdef.maxMotorForce = force
		pdef.motorSpeed = speed
		pdef.enableMotor = True

		Local joint:=world.CreateJoint(pdef)

		Return b2PrismaticJoint(joint)
	End
	
	Function RemoveFixture:Void(body:b2Body,fixture:b2Fixture)
		body.DestroyFixture fixture
	End
	

	Method Update:Void()
		world.TimeStep(TIMESTEP, SPEEDLOOPS, POSLOOPS)
		world.ClearForces()
	End
		
	Method Draw:Void()
		world.DrawDebugData()
	End

End

Class DebugDraw Extends b2DebugDraw
	Method Clear:Void()
	End
End

Const STATICBIT%=1
Const MACHINEBIT%=2
Const ROCKBIT%=4
Const BOTBIT%=8

Const DYNAMICBITS% = MACHINEBIT+ROCKBIT+BOTBIT
Const INANIMATEBITS% = STATICBIT+ROCKBIT

Class Part
	Field body:Body
	Field joint:b2RevoluteJoint
	Method New(body0:Body,joint0:b2RevoluteJoint)
		body=body0
		joint=joint0
	End
End

Class Metric
	Const Head%=0
	Const Shoulder%=1
	Const Back%=2
	Const Elbow%=3
	Const Hip%=4
	Const Wrist%=5
	Const Finger%=6
	Const Knee%=7
	Const Ankle%=8
	Const Foot%=9
	Const JointNames$[]=["head","shoulder","back","elbow","hips","wrist","finger","knee","ankle","foot"]

	Global Constraints%[]=[
		-3,3,
		-1,3,
		-2,6,
		-18,6,
		-4,4,
		-8,1,
		-8,8,
		-5,5,
		-1,14,
		-3,7,
		0,0]

	Field metrics%[]
	Method New(metrics0%[])
		metrics=metrics0
	End
	Const mm#=0.1
	Method GetX#(metric%)
		Return mm*metrics[metric*3+0]
	End
	Method GetY#(metric%)
		Return mm*metrics[metric*3+1]
	End
	Method GetR#(metric%)
		Return mm*metrics[metric*3+2]
	End
	Const rr#=PI/16.0
	Method GetM0#(metric%)
		Return rr*Constraints[metric*2+0]
	End
	Method GetM1#(metric%)
		Return rr*Constraints[metric*2+1]
	End
End

Class Biped
	Field world:Sim
	Field metric:Metric

	Field hips:Body
	Field x#,y#
	Field parts:Part[16]

	Const Hips%=0
	Const Back%=1
	Const Shoulder%=2
	Const Head%=3
	Const Left%=4
	Const Right%=10
	Const Elbow%=0
	Const Wrist%=1
	Const Finger%=2
	Const Knee%=3
	Const Ankle%=4
	Const Foot%=5

	Method New (world0:Sim,metrics%[],x0#,y0#)
		world=world0
		metric=New Metric(metrics)

		x=x0
		y=y0
		Local HipX#=metric.GetX(Metric.Hip)
		Local HipY#=metric.GetY(Metric.Hip)
		Local HipR#=metric.GetR(Metric.Hip)
		
		hips = world.CreateBody(x+HipX,y-HipY)
		Local r#=HipR
		hips.AddRadialFixture(0,0,r,BOTBIT,STATICBIT|DYNAMICBITS)
				
		parts[Hips]=New Part(hips,Null)
		parts[Back]=AddPart(Hips,Metric.Back,Metric.Hip)
		parts[Shoulder]=AddPart(Back,Metric.Shoulder,Metric.Back)
		parts[Head]=AddPart(Shoulder,Metric.Head,Metric.Shoulder)

		parts[Left+Knee]=AddPart(Hips,Metric.Knee,Metric.Hip)
		parts[Left+Ankle]=AddPart(Left+Knee,Metric.Ankle,Metric.Knee)
		parts[Left+Foot]=AddPart(Left+Ankle,Metric.Foot,Metric.Ankle)

		parts[Left+Elbow]=AddPart(Shoulder,Metric.Elbow,Metric.Shoulder)
		parts[Left+Wrist]=AddPart(Left+Elbow,Metric.Wrist,Metric.Elbow)
		parts[Left+Finger]=AddPart(Left+Wrist,Metric.Finger,Metric.Wrist)

		parts[Right+Knee]=AddPart(Hips,Metric.Knee,Metric.Hip)
		parts[Right+Ankle]=AddPart(Right+Knee,Metric.Ankle,Metric.Knee)
		parts[Right+Foot]=AddPart(Right+Ankle,Metric.Foot,Metric.Ankle)

		parts[Right+Elbow]=AddPart(Shoulder,Metric.Elbow,Metric.Shoulder)
		parts[Right+Wrist]=AddPart(Right+Elbow,Metric.Wrist,Metric.Elbow)
		parts[Right+Finger]=AddPart(Right+Wrist,Metric.Finger,Metric.Wrist)
	End
	
	Method AddPart:Part(parent%,metric1%,metric0%)
		Local pin:=parts[parent]
		Local path#[6]
		
		Local x0#=metric.GetX(metric0)
		Local y0#=metric.GetY(metric0)
		path[0]=0
		path[1]=0
		path[2]=metric.GetR(metric0)
		
		path[3]=metric.GetX(metric1)-x0
		path[4]=y0-metric.GetY(metric1)
		path[5]=metric.GetR(metric1)
			
		Local body:=world.CreateBody(x+x0,y-y0)
		body.AddPathFixture path,BOTBIT,INANIMATEBITS
		
		Local m0#=metric.GetM0(metric1)
		Local m1#=metric.GetM1(metric1)

		Local joint:=world.CreateRevolute(pin.body,body,m0,m1)

		Return New Part(body,joint)
	End
End

	
Class Box2DSeven Extends App

	Field world:Sim
	Field ground:Body
	Field bot:Biped
	Field renderCount%

	Method ResetWorld:Void()
		world=New Sim(0,10)
		bot=New Biped(world,SAMetrics,200,400)
		ground=AddBlock(0,450,600,10)
	End

	Method OnCreate%()
		ResetWorld
		SetUpdateRate 30
		Return 0
	End
		
	Method AddBlock:Body(x#,y#,w#,h#)
		Local block:Body
		block = world.CreateStatic(x,y)
		block.AddSquareFixture(w,h,STATICBIT,DYNAMICBITS)
		Return block
	End

	Method AddChasis:Body(x#,y#,w#,h#)
		Local block:Body
		block = world.CreateBody(x,y)
		block.AddSquareFixture(w,h,MACHINEBIT,INANIMATEBITS)
		Return block
	End

	Method AddPivot:Part(pin:Body,x#,y#)
		Local wheel:Body
		wheel = world.CreateBody(x,y,b2Body.b2_Body)
		wheel.density=20
		Local r#=8
		wheel.AddRadialFixture(0,0,r,MACHINEBIT,INANIMATEBITS)
		Return New Part(wheel,Null)
	End

	Method AddWheel:Part(pin:Body,x#,y#,r#)
		Local wheel:Body
		wheel = world.CreateBody(x,y,b2Body.b2_Body)
		wheel.density=2
		wheel.AddRadialFixture(0,0,r,MACHINEBIT,INANIMATEBITS)
		Local joint:=world.CreateRevolute(pin,wheel,0,0)
		Return New Part(wheel,joint)
	End

	Method AddBucket:Part(pin:Body,x#,y#)
		Local body:Body
		body = world.CreateBody(x,y,b2Body.b2_Body)
		body.density=2
		body.AddPathFixture BucketPoints,MACHINEBIT,INANIMATEBITS
		Local joint:=world.CreateRevolute(pin,body,-PI/4, PI/4)
		Return New Part(body,joint)
	End

	Method AddArm:Part(pin:Body,x#,y#)
		Local body:Body
		body = world.CreateBody(x,y,b2Body.b2_Body)
		body.density=2
		body.AddPathFixture ArmPoints,MACHINEBIT,INANIMATEBITS
		Local joint:=world.CreateRevolute(pin,body,-PI/4, PI/4)
		Return New Part(body,joint)
	End
		
	Method AddBall:Body()
		Local ball:Body
		ball = world.CreateBody(300,2)
		ball.AddRadialFixture(0,0,10,ROCKBIT,STATICBIT|DYNAMICBITS)
		ball.ApplyImpulse(Rnd(-.1,.1), 0)
		Return ball
	End
	
	Method OnUpdate%()
		If KeyHit(KEY_F1) ResetWorld
		If KeyHit(KEY_F2) AddBall

		Local m0%=KeyDown(KEY_X)-KeyDown(KEY_Z)
		Local m1%=KeyDown(KEY_S)-KeyDown(KEY_A)
		Local m2%=KeyDown(KEY_W)-KeyDown(KEY_Q)
		
		Local m3%=KeyDown(KEY_V)-KeyDown(KEY_C)
		Local m4%=KeyDown(KEY_F)-KeyDown(KEY_D)
		Local m5%=KeyDown(KEY_R)-KeyDown(KEY_E)

		Local m6%=KeyDown(KEY_N)-KeyDown(KEY_B)
		Local m7%=KeyDown(KEY_H)-KeyDown(KEY_G)
		Local m8%=KeyDown(KEY_Y)-KeyDown(KEY_T)

		Local m9%=KeyDown(KEY_COMMA)-KeyDown(KEY_M)
		Local m10%=KeyDown(KEY_K)-KeyDown(KEY_J)
		Local m11%=KeyDown(KEY_I)-KeyDown(KEY_U)

		Local m12%=KeyDown(KEY_RIGHT)-KeyDown(KEY_LEFT)
		Local m13%=KeyDown(KEY_DOWN)-KeyDown(KEY_UP)

		Local f#=1
		
		bot.parts[Biped.Back].joint.SetMotorSpeed m0*f
		bot.parts[Biped.Shoulder].joint.SetMotorSpeed m1*f
		bot.parts[Biped.Head].joint.SetMotorSpeed m2*f
		
		Const Left%=Biped.Left
		bot.parts[Left+Biped.Elbow].joint.SetMotorSpeed m3*f
		bot.parts[Left+Biped.Wrist].joint.SetMotorSpeed m4*f
		bot.parts[Left+Biped.Finger].joint.SetMotorSpeed m5*f

		bot.parts[Left+Biped.Knee].joint.SetMotorSpeed m6*f
		bot.parts[Left+Biped.Ankle].joint.SetMotorSpeed m7*f
		bot.parts[Left+Biped.Foot].joint.SetMotorSpeed m8*f

		Const Right%=Biped.Right
		bot.parts[Right+Biped.Knee].joint.SetMotorSpeed m9*f
		bot.parts[Right+Biped.Ankle].joint.SetMotorSpeed m10*f
		bot.parts[Right+Biped.Foot].joint.SetMotorSpeed m11*f

		bot.parts[Right+Biped.Elbow].joint.SetMotorSpeed -m3*f
		bot.parts[Right+Biped.Wrist].joint.SetMotorSpeed -m4*f
		bot.parts[Right+Biped.Finger].joint.SetMotorSpeed -m5*f

		'	Const JointNames$[]=["head","neck","shoulder","back","elbow","hips","wrist","finger","knee","ankle","foot"]

		'		bot.parts[Biped.Hips].joint.SetMotorSpeed m13*f
		'		bot.parts[Biped.Finger].joint.SetMotorSpeed m12*f
		'
		world.Update
		Return 0
	End

	Method OnRender%()
		renderCount+=1
		Cls 10,30,160
		world.Draw
		Return 0
	End
End

Function Main%()
	New Box2DSeven
	Return 0
End