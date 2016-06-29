particleColors = [
  new b2ParticleColor(0xff, 0x00, 0x00, 0xff)
  new b2ParticleColor(0x00, 0xff, 0x00, 0xff)
  new b2ParticleColor(0x00, 0x00, 0xff, 0xff)
  new b2ParticleColor(0xff, 0x8c, 0x00, 0xff)
  new b2ParticleColor(0x00, 0xce, 0xd1, 0xff)
  new b2ParticleColor(0xff, 0x00, 0xff, 0xff)
  new b2ParticleColor(0xff, 0xd7, 0x00, 0xff)
  new b2ParticleColor(0x00, 0xff, 0xff, 0xff)
]

container          = undefined
world              = null
threeRenderer      = undefined
renderer           = undefined
camera             = undefined
scene              = undefined
objects            = []
timeStep           = 1.0 / 60.0
velocityIterations = 8
positionIterations = 3
test               = {}
projector          = new (THREE.Projector)
planeZ             = new (THREE.Plane)(new (THREE.Vector3)(0, 0, 1), 0)
g_groundBody       = null
windowWidth        = window.innerWidth
windowHeight       = window.innerHeight

render = ->
  # bring objects into world
  renderer.currentVertex = 0
  if test.Step != undefined
    test.Step()
  else
    Step()
  renderer.draw()
  threeRenderer.render scene, camera
  requestAnimationFrame render

ResetWorld = ->
  if world != null
    while world.joints.length > 0
      world.DestroyJoint world.joints[0]
    while world.bodies.length > 0
      world.DestroyBody world.bodies[0]
    while world.particleSystems.length > 0
      world.DestroyParticleSystem world.particleSystems[0]
  camera.position.x = 0
  camera.position.y = 0
  camera.position.z = 100

Step = -> world.Step timeStep, velocityIterations, positionIterations

initTestbed = ->
  camera = new (THREE.PerspectiveCamera)(70, windowWidth / windowHeight, 1, 1000)
  try
    threeRenderer = new (THREE.WebGLRenderer)
  catch error
    return console.log "Browser does not support WebGL"

  threeRenderer.setClearColor 0xEEEEEE
  threeRenderer.setSize windowWidth, windowHeight
  camera.position.x = 0
  camera.position.y = 0
  camera.position.z = 100
  scene = new (THREE.Scene)
  camera.lookAt scene.position
  document.body.appendChild @threeRenderer.domElement
  @mouseJoint = null
  # hack
  renderer = new Renderer
  gravity  = new b2Vec2(0, -10)
  world    = new b2World(gravity)
  window.world = world
  Testbed()

Testbed = (obj) ->

  that = this

  document.addEventListener 'keypress', (event) ->
    if test.Keyboard != undefined
      test.Keyboard String.fromCharCode(event.which)
    return

  document.addEventListener 'keyup', (event) ->
    if test.KeyboardUp != undefined
      test.KeyboardUp String.fromCharCode(event.which)
    return

  document.addEventListener 'mousedown', (event) ->
    p = getMouseCoords(event)
    aabb = new b2AABB
    d = new b2Vec2
    d.Set 0.01, 0.01
    b2Vec2.Sub aabb.lowerBound, p, d
    b2Vec2.Add aabb.upperBound, p, d
    queryCallback = new QueryCallback(p)
    world.QueryAABB queryCallback, aabb
    if queryCallback.fixture
      body = queryCallback.fixture.body
      md = new b2MouseJointDef
      md.bodyA = g_groundBody
      md.bodyB = body
      md.target = p
      md.maxForce = 1000 * body.GetMass()
      that.mouseJoint = world.CreateJoint(md)
      body.SetAwake true
    if test.MouseDown != undefined
      test.MouseDown p
    return

  document.addEventListener 'mousemove', (event) ->
    p = getMouseCoords(event)
    if that.mouseJoint
      that.mouseJoint.SetTarget p
    if test.MouseMove != undefined
      test.MouseMove p
    return

  document.addEventListener 'mouseup', (event) ->
    if that.mouseJoint
      world.DestroyJoint that.mouseJoint
      that.mouseJoint = null
    if test.MouseUp != undefined
      test.MouseUp getMouseCoords(event)
    return

  window.addEventListener 'resize', onWindowResize, false
  ResetWorld()
  world.SetGravity new b2Vec2(0, -10)
  bd = new b2BodyDef
  g_groundBody = world.CreateBody(bd)
  test = new (window['TestOrientation'])
  render()

QueryCallback = (point) ->
  @point = point
  @fixture = null

onWindowResize = ->
  camera.aspect = window.innerWidth / window.innerHeight
  camera.updateProjectionMatrix()
  threeRenderer.setSize window.innerWidth, window.innerHeight

getMouseCoords = (event) ->
  mouse = new (THREE.Vector3)
  mouse.x = event.clientX / windowWidth * 2 - 1
  mouse.y = -(event.clientY / windowHeight) * 2 + 1
  mouse.z = 0.5
  projector.unprojectVector mouse, camera
  dir = mouse.sub(camera.position).normalize()
  distance = -camera.position.z / dir.z
  pos = camera.position.clone().add(dir.multiplyScalar(distance))
  p = new b2Vec2(pos.x, pos.y)
  p

QueryCallback::ReportFixture = (fixture) ->
  body = fixture.body
  if body.GetType() == b2_dynamicBody
    inside = fixture.TestPoint(@point)
    if inside
      @fixture = fixture
      return true
  false

TestOrientation = ->

  camera.position.y = 4
  camera.position.z = 8

  bd = new b2BodyDef
  ground = world.CreateBody(bd)

  base                = new b2PolygonShape
  base.vertices       = [ new b2Vec2(-10, -1), new b2Vec2(10, -1), new b2Vec2(10, -0.1), new b2Vec2(-10, -0.1) ] 
  leftBlock           = new b2PolygonShape
  leftBlock.vertices  = [ new b2Vec2(-8, -0.1), new b2Vec2(-6, -0.1), new b2Vec2(-6, 2), new b2Vec2(-8, 3) ]
  rightBlock          = new b2PolygonShape
  rightBlock.vertices = [ new b2Vec2(6, -0.1), new b2Vec2(8, -0.1), new b2Vec2(8, 3), new b2Vec2(6, 2) ]

  ground.CreateFixtureFromShape base, 0
  ground.CreateFixtureFromShape leftBlock, 0
  ground.CreateFixtureFromShape rightBlock, 0

  psd = new b2ParticleSystemDef
  psd.radius = 0.035
  particleSystem = world.CreateParticleSystem(psd)

  circle = new b2CircleShape
  circle.position.Set 0, 2
  circle.radius = 2
  pgd = new b2ParticleGroupDef
  pgd.shape = circle
  pgd.color.Set 55, 55, 255, 255
  particleSystem.CreateParticleGroup pgd

deviceOrientationListener = (event) ->
  horizontalSlide = Math.round(event.beta)  # Backwards +, Forward -
  verticalSlide   = Math.round(event.gamma) # Right +, Left -
  world.SetGravity new b2Vec2( verticalSlide * 0.2, -10 )

if window.DeviceOrientationEvent
  window.addEventListener 'deviceorientation', deviceOrientationListener

document.addEventListener( "DOMContentLoaded", ()->
  initTestbed()
)