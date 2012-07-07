class Walker
  constructor: ->
    @mvMatrixStack = []
    @mvMatrix = Matrix.I(4);

    @zoom = -5;
    @rotation_x = 0
    @rotation_y = 0
    @currentlyPressedKeys = []
    @currentTime = (new Date).getTime()
    @clicked = false

    document.onkeyup   = @handleKeyUp;
    document.onkeydown = @handleKeyDown;

    canvas = document.getElementById("canvas")
    canvas.onmousedown = @handleMouseDown
    document.onmouseup = @handleMouseUp
    document.onmousemove = @handleMouseMove


    @models = []
    @models[0] = new window.Sketchup

    if gl
      gl.clearColor(0.0, 0.0, 0.0, 1.0);  # Clear to black, fully opaque
      gl.clearDepth(1.0);                 # Clear everything
      gl.enable(gl.DEPTH_TEST);           # Enable depth testing
      gl.depthFunc(gl.LEQUAL);            # Near things obscure far things

      gl.initShaders()

      # @initBuffers(gl)
      model.buffer() for model in @models

      @start()

  start: ->
    setInterval(@drawLoop, 15, @);

  drawLoop: (scope) ->
    scope.drawScene()

  handleMouseDown: (event) ->
    window.walker.startMoveCamera([event.x, event.y])

  handleMouseUp: (event) ->
    window.walker.endMoveCamera()

  handleMouseMove: (event) ->
    window.walker.moveCamera([event.x, event.y])

  handleKeyDown: (event) ->
    window.walker.currentlyPressedKeys[event.keyCode] = true

  handleKeyUp: (event) ->
    window.walker.currentlyPressedKeys[event.keyCode] = false

  startMoveCamera: (pos) ->
    @clicked = true
    @previousMousePosition = pos

  endMoveCamera: ->
    @clicked = false

  moveCamera: (pos) ->
    if @clicked
      @rotation_x += @previousMousePosition[0] - pos[0]
      @rotation_y += @previousMousePosition[1] - pos[1]

      @previousMousePosition = pos

  handleKeys: ->
    if (@currentlyPressedKeys[37])
      @rotation_x -= 360*@dt();
    if (@currentlyPressedKeys[39])
      @rotation_x += 360*@dt();

    if (@currentlyPressedKeys[40])
      @rotation_y -= 360*@dt();
    if (@currentlyPressedKeys[38])
      @rotation_y += 360*@dt();

    if (@currentlyPressedKeys[187])
      @zoom *= 0.9;
    if (@currentlyPressedKeys[189])
      @zoom *= 1.1;

  dt: ->
    return (((new Date).getTime() - @currentTime) / 1000);


  drawScene: ->
    # this = scope
    @handleKeys();

    gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);

    gl.perspectiveMatrix = makePerspective(45, 640.0/480.0, 0.1, 100000.0);

    gl.loadIdentity();

    gl.mvTranslate([-0.0, 0.0, @zoom]);
    gl.mvRotate(@rotation_y, [1, 0, 0]);
    gl.mvRotate(@rotation_x, [0, 1, 0]);
    gl.mvRotate(-90, [1, 0, 0]);

    for model in @models
      gl.mvPushMatrix();
      model.draw()
      gl.mvPopMatrix();

    @currentTime = (new Date).getTime();

window.walker_object = Walker

