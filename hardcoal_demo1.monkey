#Rem

'Im still very new at box2d but im starting to understand its principle.
'its not an easy to understand engine since the tutorials are not dealing with explaning the core principle of this engine.
'I will try to do that with what ive figured out till now.

'In box2d you First define things and then create them.
'First you define the your 2D world.

'Example:
Field BXworld				: b2World					'Box2D physical World Object
Field m_velocityIterations	: int 	= 10				'Dont know whats this yet.
Field m_positionIterations	: int 	= 10				'Either that.
Field m_timeStep			: Float = 1.0/60			'Hmm, I know whats this but no changes accured when presetting.
Field m_physScale			: Float = 1 ' 30       		'I Change its value but same results.
Field m_debugdrawscale		: Float	= 10
	
Then you create it.
BXworld = New b2World(New b2Vec2(0,9.7),True)
	
Now that you have created your world you can create objects.
Same here, first you need to define the object and then create it.

Example:
	Field ABody:b2Body				'The Actual Body
Field BodyDef:b2BodyDef
Field BodyShape:b2PolygonShape
Field BodyFixture:b2FixtureDef
	
BodyDef.type=b2Body.b2_Body	'A dynamic body set
BodyFixture.density 		=1.0
BodyFixture.friction 		=0.5
BodyFixture.restitution 	=0.1
BodyShape.SetAsBox(10,10)
BodyFixture.shape=BodyShape
	
You create the object using the World...
	
ABody=BXworld.CreateBody(BodyDef)
ABody.CreateFixture(BodyFixture)
	 
I still not totaly understand this engine but you can run the demo and check stuff out.
My next demo will be a joint demo.

#End


'----Imports----'
Import box2d.collision
Import box2d.collision.shapes
Import box2d.common.math
Import box2d.dynamics.contacts
Import box2d.dynamics
Import box2d.flash.flashtypes
Import box2d.common.math.b2vec2

'----Test Zone----'
Function Main()
	New Box2DLoop
End Function

'----Main Loop----'

Class Box2DLoop extends App

	'Box 2D World Definitions
	Field BXworld				: b2World					'Box2D physical World Object
	Field m_velocityIterations	: int 	= 10				'Dont know whats this yet.
	Field m_positionIterations	: int 	= 10				'Either that.
	Field m_timeStep			: Float = 1.0/60			'Hmm, I know whats this but no changes accured when presetting.
	Field m_physScale			: Float = 1 ' 30       		'I Change its value but same results.
	Field m_debugdrawscale		: Float	= 10	 			'This Affects the size of the physical Body Display
			
	'A Box2D Object Definition
	Field ABody:b2Body			'The Actual Body
	Field BodyDef:b2BodyDef
	Field BodyShape:b2PolygonShape
	Field BodyFixture:b2FixtureDef
	
	Method OnCreate()
	
		'Display Setup
		SetUpdateRate(60)
	
		'--Box2D Section--'
		
		'World Setups
		BXworld = New b2World(New b2Vec2(0,9.7),True)
				
		'Creating a Simple Box (simple.. right..)
		BodyDef	=New b2BodyDef
		BodyShape	=New b2PolygonShape()
		BodyFixture=New b2FixtureDef
		 
		BodyDef.type=b2Body.b2_Body	'A dynamic body set
		BodyFixture.density 		=1.0
		BodyFixture.friction 		=0.5
		BodyFixture.restitution 	=0.1
		BodyShape.SetAsBox(10,10)
		BodyFixture.shape=BodyShape
		 
		ABody=BXworld.CreateBody(BodyDef)
		ABody.CreateFixture(BodyFixture)
		ABody.SetPosition(New b2Vec2(20,20))
		 			
		'Debug Settings  'Delete this section if you dont need to see the physical process.
		Local dbgDraw :b2DebugDraw = New b2DebugDraw()
		dbgDraw.SetDrawScale(m_debugdrawscale)
		dbgDraw.SetFillAlpha(0.3)
		dbgDraw.SetLineThickness(1.0)
		dbgDraw.SetFlags(b2DebugDraw.e_shapeBit | b2DebugDraw.e_jointBit)'| b2DebugDraw.e_pairBit)
		
		BXworld.SetDebugDraw(dbgDraw)
		
	End Method
	
	Method OnRender()
		Cls
		'Box2D Display Section
		BXworld.DrawDebugData() 'Delete this line if you dont need to see the physical process in graphics. (must also delete 'Box2D Debug Settings section above)
	End Method
	
	Method OnUpdate()
		'The Stepping of Box2D Engine
		BXworld.TimeStep(m_timeStep,m_velocityIterations,m_positionIterations)
		BXworld.ClearForces()													'Dont know why you need this..
	End Method
		
End Class