' pendulum.monkey

' F1 - reset
' F2 - add ball
' ESC - quit
'http://www.box2d.org/manual.html
'http://www.iforce2d.net/b2dtut/forces
Strict

Import mojo
Import box2d.collision
Import box2d.dynamics.joints

Const FRAMERATE:Int = 30

Const TIMESTEP:Float = 1.0 / FRAMERATE

'Iterations for solvers (velocity solver and position solver)

Const VELOCITY_ITERATIONS:Int = 6
Const POSITION_ITERATIONS:Int = 3

'Divide pixel coordinates by this to have the World coordinates.
'If 1 pixel is one meter, this is making huge objects and all looks like slow.
'A good rule is 1 meter = 128 pixels, so, divide pixel measures by 128

Const PHYS_SCALE_PIXELS_PER_METER:Float = 128.0
Const SCREEN_WIDTH:= 1024
Const SCREEN_HEIGHT:= 768

Const SCREEN_WIDTH2:= 1024 / 2
Const SCREEN_HEIGHT2:= 768 / 2

Function toBoxCoords:b2Vec2(userUnitsVec:b2Vec2)

	Return New b2Vec2( (SCREEN_WIDTH2 + userUnitsVec.x) / PHYS_SCALE_PIXELS_PER_METER, (SCREEN_HEIGHT2 + userUnitsVec.y) / PHYS_SCALE_PIXELS_PER_METER)
	
End

Function toRelativeBoxCoords:b2Vec2(userUnitsVec:b2Vec2)

	Return New b2Vec2(userUnitsVec.x / PHYS_SCALE_PIXELS_PER_METER, userUnitsVec.y / PHYS_SCALE_PIXELS_PER_METER)
	
End


Class PendulumWorld

	Field world:b2World
	
	Method New()
		Init()
	End

	Method Init:Void()
	
		' Allow bodies to sleep
		Local doSleep:Bool = True
		
		Local gravity:b2Vec2 = New b2Vec2(0, 10)
		
		' Construct a world object
		world = New b2World(gravity, doSleep)
		world.SetWarmStarting(True)
		
		Local dbgDraw:= New DebugDraw()
		
		'This affects the way things are drawn scale wise.
		dbgDraw.SetDrawScale(PHYS_SCALE_PIXELS_PER_METER)
		
		dbgDraw.SetFillAlpha(0.90)
		dbgDraw.SetLineThickness(1.0)
		dbgDraw.SetFlags(b2DebugDraw.e_shapeBit | b2DebugDraw.e_jointBit)'| b2DebugDraw.e_pairBit)
		world.SetDebugDraw(dbgDraw)
	End
	
	Method Update:Void()
		world.TimeStep(TIMESTEP, VELOCITY_ITERATIONS, POSITION_ITERATIONS)
		world.ClearForces()
	End
		
	Method Draw:Void()
		world.DrawDebugData()
	End

	Global FixtureDef:=New b2FixtureDef()
	Global BodyDef:=New b2BodyDef()
		
	'Pass coordinates in screen pixels relative to screen center
	'Always remember that (x,y) is the center of the object
	'angularDamping between 0 and 0.01
	'0 = do damping
	'inf = full damping
	Method CreateBody:b2Body(x:Float, y:Float, bodytype:Int, linearDamping:Float = 0, angularDamping:Float = 0, fixedRotation:Bool = False)
		BodyDef.type = bodytype
		BodyDef.fixedRotation=False
		BodyDef.position.Set( (SCREEN_WIDTH2 + x) / PHYS_SCALE_PIXELS_PER_METER, (SCREEN_HEIGHT2 + y) / PHYS_SCALE_PIXELS_PER_METER)
		BodyDef.linearDamping = linearDamping
		BodyDef.angularDamping = angularDamping
		BodyDef.fixedRotation = fixedRotation
		Return world.CreateBody(BodyDef)
	End
	
	
	Method AddRadialFixture:b2Fixture(body:b2Body, r:Float, bits:Int, mask:Int)
		FixtureDef.shape = New b2CircleShape(r / PHYS_SCALE_PIXELS_PER_METER)
		FixtureDef.density=10
		FixtureDef.filter.categoryBits=bits
		FixtureDef.filter.maskBits = mask
		
		Local fixture:= body.CreateFixture(FixtureDef)
		fixture.SetRestitution(0.1)
		fixture.SetFriction(0.9)
		Return fixture
	End

	Method AddSquareFixture:b2Fixture(body:b2Body, w:Float, h:Float, bits:Int, mask:Int)
		Local shape:=New b2PolygonShape
		shape.SetAsBox w / PHYS_SCALE_PIXELS_PER_METER, h / PHYS_SCALE_PIXELS_PER_METER
		FixtureDef.shape=shape
		FixtureDef.density=10
		FixtureDef.filter.categoryBits=bits
		FixtureDef.filter.maskBits=mask
		Local fixture:=body.CreateFixture(FixtureDef)
		fixture.SetRestitution(0.1)
		fixture.SetFriction(0.9)
		Return fixture
	End
	
	Method ApplyForceToBody:Void(force:b2Vec2, body:b2Body)
		body.ApplyForce(force, body.GetPosition())
	End

End

Class DebugDraw Extends b2DebugDraw
	Method Clear:Void()
	End
End


Const STATICBIT%=1
Const DYNAMICBIT%=2

Class PendulumApp Extends App

	Field world:PendulumWorld
	Field renderCount:Int
	Field ground:b2Body
	Field pendulumBall:b2Body
	Field pendulumShaft:b2Body
	Field ceilingAttachment:b2Body
	Field jointDef:b2DistanceJointDef
	Field revoluteJointDef:b2RevoluteJointDef
	Field revoluteJointCeilingDef:b2RevoluteJointDef
	Field joint:b2Joint
	Field jointCeiling:b2Joint
	Field debugRender:Bool = False

	Method OnCreate:Int()
		ResetWorld
		AddStuff
		SetUpdateRate FRAMERATE
		debugRender = True
		Return 0
	End
	
	Method ResetWorld:Void()
		world = New PendulumWorld
		
		ground = world.CreateBody(0, 220, b2Body.b2_staticBody)
		world.AddSquareFixture(ground, 200, 10, STATICBIT, DYNAMICBIT)
	End
	
	Method AddStuff:Void()
		pendulumBall = world.CreateBody(0, 0, b2Body.b2_Body, 0, 2, True)
		pendulumShaft = world.CreateBody(0, -100, b2Body.b2_Body)
		ceilingAttachment = world.CreateBody(0, -100 * 2, b2Body.b2_staticBody)

		world.AddRadialFixture(ceilingAttachment, 5, STATICBIT, STATICBIT | DYNAMICBIT)
		world.AddRadialFixture(pendulumBall, 20, DYNAMICBIT, STATICBIT | DYNAMICBIT)
		world.AddSquareFixture(pendulumShaft, 2, 100, DYNAMICBIT, STATICBIT | DYNAMICBIT)
		
		#rem
		jointDef = New b2DistanceJointDef()
		
		' http://www.iforce2d.net/b2dtut/joints-revolute
		jointDef.Initialize(
			pendulumBall,
			pendulumShaft,
			toBoxCoords(New b2Vec2(0, 0)),
			toBoxCoords(New b2Vec2(0, 0)))
			
		jointDef.collideConnected = False
		jointDef.frequencyHz = 0.0
		jointDef.dampingRatio = 0.0
		#end
		
		Local anchorPoint:= toBoxCoords(New b2Vec2(0, 0))
		' try to use pendulumBall.body.getWorldCenter()
		revoluteJointDef = New b2RevoluteJointDef()
		revoluteJointDef.Initialize(
			pendulumBall,
			pendulumShaft,
			anchorPoint)
			
		' joint = world.world.CreateJoint(jointDef)
		joint = world.world.CreateJoint(revoluteJointDef)
		
		Local anchorPointCeiling:= toBoxCoords(New b2Vec2(0, -200))
		
		'This will need some organization of things at one point
		revoluteJointCeilingDef = New b2RevoluteJointDef()
		revoluteJointCeilingDef.maxMotorTorque = 0.0;
		revoluteJointCeilingDef.motorSpeed = 0.0;
		revoluteJointCeilingDef.enableMotor = False;
		revoluteJointCeilingDef.Initialize(
			ceilingAttachment,
			pendulumShaft,
			anchorPointCeiling)

		jointCeiling = world.world.CreateJoint(revoluteJointCeilingDef)
		
		world.ApplyForceToBody(New b2Vec2(60, 0), pendulumBall)
		
	End
	
	Method OnUpdate:Int()
		If KeyHit(KEY_F1) ResetWorld
		If KeyHit(KEY_F2) AddStuff
		If KeyHit(KEY_ESCAPE)
			EndApp()
		End
		If KeyHit(KEY_SPACE)
			debugRender = Not debugRender
		EndIf
		Local clicked:Int = MouseHit(0) - MouseHit(1)
		If clicked
			Local worldPoint:b2Vec2 = New b2Vec2(
				MouseX() / PHYS_SCALE_PIXELS_PER_METER,
				MouseY() / PHYS_SCALE_PIXELS_PER_METER)
		
			pendulumBall.ApplyForce(New b2Vec2(clicked * 60, 0), worldPoint)
		EndIf
		world.Update
		Return 0
	End

	Method OnRender:Int()
		renderCount+=1
		Cls 10, 70, 120
		Local ceilingAttachmentPosition:b2Vec2 = ceilingAttachment.GetPosition()
		ceilingAttachmentPosition.Multiply(PHYS_SCALE_PIXELS_PER_METER)
		Local pendulumBallPosition:b2Vec2 = pendulumBall.GetPosition()
		pendulumBallPosition.Multiply(PHYS_SCALE_PIXELS_PER_METER)
		SetColor(0, 255, 0)
		DrawLine(
			ceilingAttachmentPosition.x, ceilingAttachmentPosition.y,
			pendulumBallPosition.x, pendulumBallPosition.y)
		SetColor(255, 0, 0)
		DrawCircle(pendulumBallPosition.x, pendulumBallPosition.y, 20)
		
		If debugRender
			world.Draw()
		EndIf
		
		Return 0
	End
End

Function Main:Int()
	New PendulumApp
	Return 0
End
