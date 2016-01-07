' box2done.monkey

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

Class Box2D

	Field world:b2World
	
	Method New()
		Init New b2Vec2(0,10)
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
	
	Method Update:Void()
		world.TimeStep(TIMESTEP, SPEEDLOOPS, POSLOOPS)
		world.ClearForces()
	End
		
	Method Draw:Void()
		world.DrawDebugData()
	End

	Global FixtureDef:=New b2FixtureDef()
	Global BodyDef:=New b2BodyDef()
	Global Impulse:=New b2Vec2
		
	Method CreateBody:b2Body(x#,y#,bodytype%)
		BodyDef.type = bodytype
		BodyDef.fixedRotation=False
		BodyDef.position.Set(x,y)
		Return world.CreateBody(BodyDef)
	End
	
	Method AddRadialFixture:b2Fixture(body:b2Body,r#,bits%,mask%)
		FixtureDef.shape=New b2CircleShape(r*WORLDSCALE)
		FixtureDef.density=10
		FixtureDef.filter.categoryBits=bits
		FixtureDef.filter.maskBits=mask
		Local fixture:=body.CreateFixture(FixtureDef)
		fixture.SetRestitution(0.1)
		fixture.SetFriction(0.9)
		Return fixture
	End

	Method AddSquareFixture:b2Fixture(body:b2Body,w#,h#,bits%,mask%)
		Local shape:=New b2PolygonShape
		shape.SetAsBox w*WORLDSCALE,h*WORLDSCALE
		FixtureDef.shape=shape
		FixtureDef.density=10
		FixtureDef.filter.categoryBits=bits
		FixtureDef.filter.maskBits=mask
		Local fixture:=body.CreateFixture(FixtureDef)
		fixture.SetRestitution(0.1)
		fixture.SetFriction(0.9)
		Return fixture
	End
	
	Method ApplyImpulse:Void(body:b2Body,x#,y#)
		Impulse.x=x
		Impulse.y=y
		body.ApplyForce Impulse,body.GetPosition()
	End

End

Class DebugDraw Extends b2DebugDraw
	Method Clear:Void()
	End
End


Const STATICBIT%=1
Const DYNAMICBIT%=2

Class Box2DOne Extends App

	Field world:Box2D
	Field renderCount%

	Method OnCreate%()
		ResetWorld
		AddBall
		SetUpdateRate 30
		Return 0
	End
	
	Method ResetWorld:Void()
		world=New Box2D
		Local ground:b2Body
		ground = world.CreateBody(0,20,b2Body.b2_staticBody)
		world.AddSquareFixture(ground,100,10,STATICBIT,DYNAMICBIT)
	End
	
	Method AddBall:b2Body()
		Local ball:b2Body
		ball = world.CreateBody(10,0,b2Body.b2_Body)
		world.AddRadialFixture(ball,10,DYNAMICBIT,STATICBIT|DYNAMICBIT)
		world.ApplyImpulse(ball, Rnd(-.1,.1), 0)
		Return ball
	End
	
	Method OnUpdate%()
		If KeyHit(KEY_F1) ResetWorld
		If KeyHit(KEY_F2) AddBall
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
	New Box2DOne
	Return 0
End