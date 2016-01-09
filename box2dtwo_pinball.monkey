' box2dtwo.monkey

' F1 - reset
' F2 - add ball
' Left - left flipper

Strict

Import mojo
Import box2d.collision

Const WORLDSCALE#=1.0/8
Const TIMESTEP#=1.0/20			'frantic 2x clock
Const FRAMERATE%=30
Const SPEEDLOOPS%=20
Const POSLOOPS%=20

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


	Method AddRadialFixture:b2Fixture(r#,bits%,mask%)
		Local shape:=New b2CircleShape(r*WORLDSCALE)
		Local fixture:=AddFixture(shape,bits,mask)
		fixture.SetRestitution(1)
		fixture.SetFriction(.2)
		Return fixture
	End
	
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
	
	Method AddSquareFixture:b2Fixture(w#,h#,bits%,mask%)
		Local shape:=New b2PolygonShape
		shape.SetAsBox w*WORLDSCALE,h*WORLDSCALE
		Return AddFixture(shape,bits,mask)
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
	
	Method CreateRevolute:b2RevoluteJoint(a:Body,b:Body,x#,y#)
		Local r:=New b2RevoluteJointDef
		Local p:=New b2Vec2(x*WORLDSCALE,y*WORLDSCALE)
		r.Initialize(a.body,b.body,p)
		
		r.maxMotorTorque = 20000
		r.motorSpeed = 1000
		r.enableLimit = True
		r.enableMotor = True

		r.lowerAngle=PI/3
		r.upperAngle=2*PI/3
		
		Local joint:=world.CreateJoint(r)
		Return b2RevoluteJoint(joint)
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
Const DYNAMICBIT%=2

Class Box2DTwo Extends App

	Field world:Sim
	Field ground:Body
	Field flipper:b2RevoluteJoint
	
	Field renderCount%

	Method OnCreate%()
		ResetWorld
		AddBall
		SetUpdateRate 30
		Return 0
	End
		
	Method AddBlock:Body(x#,y#,w#,h#)
		Local block:Body
		block = world.CreateBody(x,y,b2Body.b2_staticBody)
		block.AddSquareFixture(w,h,STATICBIT,DYNAMICBIT)
		Return block
	End
	
	Method AddFlipper:b2RevoluteJoint(x#,y#)
		Local body:Body
		Local pin:Body
		pin = world.CreateBody(x,y,b2Body.b2_staticBody)
		body = world.CreateBody(x,y,b2Body.b2_Body)
		body.density=2
		Local points:=	FlipperCoords(2,1,8,32)
		body.AddPolygonFixture points,STATICBIT,DYNAMICBIT
		Local joint:=world.CreateRevolute(pin,body,x,y)
		Return joint
	End

	Method ResetWorld:Void()
		world=New Sim(0,10)
		flipper=AddFlipper(80,360)
		ground=AddBlock(0,450,600,10)
	End
	
	Method AddBall:Body()
		Local ball:Body
		ball = world.CreateBody(110,2,b2Body.b2_Body)
		ball.AddRadialFixture(10,DYNAMICBIT,STATICBIT|DYNAMICBIT)
		ball.ApplyImpulse(Rnd(-.1,.1), 0)
		Return ball
	End
	
	Method OnUpdate%()
		If KeyHit(KEY_F1) ResetWorld
		If KeyHit(KEY_F2) AddBall
		
		If KeyDown(KEY_LEFT)
			flipper.SetMotorSpeed -1000
		Else
			flipper.SetMotorSpeed 1000
		Endif
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
	New Box2DTwo
	Return 0
End