' box2dfour.monkey
' F1 - reset
' F2 - add ball
' Z,X, Arrows - turn motors

Strict

Import mojo
Import box2d.collision

Const WORLDSCALE#=1.0/8
Const TIMESTEP#=1.0/20			'frantic 2x clock
Const FRAMERATE%=30
Const SPEEDLOOPS%=20
Const POSLOOPS%=20

' point list is [x,y,r[,...]]

Global BucketPoints#[]=[
	50.0,-80,5,
	0,-40,10,
	0,40,10,
	50,80,5]

Global ArmPoints#[]=[
	0.0,0,10,
	20,-40,5,
	80,-40,5,
	100,0,10]


' two semicirlces separated by d offset  Oxo

Function FlipperCoords#[](r1#,r2#,d#,n%)
	Local pts:=New Float[n*2]
	For Local i%=0 Until n
		Local a#=(i+.5)*360.0/n
		Local x#=Cos(a)
		Local y#=Sin(a)
		If i<n/2
			x=x*r1
			y=y*r1
		Else
			x=x*r2
			y=y*r2-d
		Endif
		pts[i*2+0]=x
		pts[i*2+1]=y
	Next
	Return pts
End

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
			
	Method CreateBody:Body(x#,y#,bodytype%)
		Return New Body(world,x,y,bodytype)
	End
	
	Method CreateRevolute:b2RevoluteJoint(a:Body,b:Body,rad0#,rad1#)
		Local r:=New b2RevoluteJointDef
		Local p:=b.body.GetPosition()
		r.Initialize(a.body,b.body,p)
		r.maxMotorTorque = 20000
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

Const DYNAMICBITS% = MACHINEBIT+ROCKBIT
Const INANIMATEBITS% = STATICBIT+ROCKBIT

Class Part
	Field body:Body
	Field joint:b2RevoluteJoint
	Method New(body0:Body,joint0:b2RevoluteJoint)
		body=body0
		joint=joint0
	End
End
	
Class Box2DFour Extends App

	Field world:Sim
	Field ground:Body

	Field chasis:Body
	Field bucket:Part

	Field frontwheel:Part
	Field frontaxle:Part
	Field frontshock:b2PrismaticJoint
	Field backwheel:Part
	Field backaxle:Part
	Field backshock:b2PrismaticJoint

	Field arm:Part
	Field renderCount%

	Method ResetWorld:Void()
		world=New Sim(0,10)
		
		Local x#=300
		Local y#=100

		chasis=AddChasis(x,y,120,40)

		Local wb#=80
		Local wh#=40
		
		frontaxle=AddPivot(chasis,x-wb,y+wh)
		backaxle=AddPivot(chasis,x+wb,y+wh)

		frontwheel=AddWheel(frontaxle.body,x-wb,y+wh,wh)
		backwheel=AddWheel(backaxle.body,x+wb,y+wh,wh)

		frontshock=world.CreatePrism(chasis,x-wb,y-wh,  frontaxle.body,  .1,-1, .1,0)
		backshock=world.CreatePrism(chasis,x+wb,y-wh,  backaxle.body,  -.1,-1, .1,0)

		arm=AddArm(chasis,x+50,y-50)
		bucket=AddBucket(arm.body,x+160,y-50)
			
		ground=AddBlock(0,450,600,10)
	End

	Method OnCreate%()
		ResetWorld
		AddBall
		SetUpdateRate 30
		Return 0
	End
		
	Method AddBlock:Body(x#,y#,w#,h#)
		Local block:Body
		block = world.CreateBody(x,y,b2Body.b2_staticBody)
		block.AddSquareFixture(w,h,STATICBIT,DYNAMICBITS)
		Return block
	End
	
	Method AddChasis:Body(x#,y#,w#,h#)
		Local block:Body
		block = world.CreateBody(x,y,b2Body.b2_Body)
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
		ball = world.CreateBody(300,2,b2Body.b2_Body)
		ball.AddRadialFixture(0,0,10,ROCKBIT,STATICBIT|DYNAMICBITS)
		ball.ApplyImpulse(Rnd(-.1,.1), 0)
		Return ball
	End
	
	Method OnUpdate%()
		If KeyHit(KEY_F1) ResetWorld
		If KeyHit(KEY_F2) AddBall

		Local bucketSpeed#=0
		Local armSpeed#=0
		If KeyDown(KEY_LEFT)
			bucketSpeed=-20
		Endif
		If KeyDown(KEY_RIGHT)
			bucketSpeed=20
		Endif
		If KeyDown(KEY_UP)
			armSpeed=-400
		Endif
		If KeyDown(KEY_DOWN)
			armSpeed=400
		Endif
		If arm And bucket
			arm.joint.SetMotorSpeed armSpeed
			bucket.joint.SetMotorSpeed bucketSpeed
		Endif
		
		Local wheelSpeed#=0
		If KeyDown(KEY_X)
			wheelSpeed=10
		Endif
		If KeyDown(KEY_Z)
			wheelSpeed=-10
		Endif
		backwheel.joint.SetMotorSpeed wheelSpeed
		frontwheel.joint.SetMotorSpeed wheelSpeed

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
	New Box2DFour
	Return 0
End