@start = ->
  canvas = document.getElementById("canvas")
  window.gl = canvas.getContext("experimental-webgl")

  gl.mvMatrix = Matrix.I(4)
  gl.perspectiveMatrix = Matrix.I(4)
  gl.mvMatrixStack = []

  gl.getShader=(gl, id) ->
    shaderScript = document.getElementById(id)

    if (!shaderScript)
      return null


    theSource = ""
    currentChild = shaderScript.firstChild

    while(currentChild)
      if (currentChild.nodeType == 3)
        theSource += currentChild.textContent;

      currentChild = currentChild.nextSibling;


    if (shaderScript.type == "x-shader/x-fragment")
      shader = gl.createShader(gl.FRAGMENT_SHADER)
    else if (shaderScript.type == "x-shader/x-vertex")
      shader = gl.createShader(gl.VERTEX_SHADER)
    else
      return

    gl.shaderSource(shader, theSource)

    gl.compileShader(shader)

    if (!gl.getShaderParameter(shader, gl.COMPILE_STATUS))
      alert("An error occurred compiling the shaders: " + gl.getShaderInfoLog(shader))
      return null

    return shader

  gl.initShaders= ->
    fragmentShader = gl.getShader(gl, "shader-fs");
    vertexShader   = gl.getShader(gl, "shader-vs");

    @shaderProgram = gl.createProgram();
    gl.attachShader(@shaderProgram, vertexShader);
    gl.attachShader(@shaderProgram, fragmentShader);
    gl.linkProgram(@shaderProgram);

    if (!gl.getProgramParameter(@shaderProgram, gl.LINK_STATUS))
      alert("Could not initialise shaders")

    gl.useProgram(@shaderProgram);

    @shaderProgram.vertexPositionAttribute = gl.getAttribLocation(@shaderProgram, "aVertexPosition");
    gl.enableVertexAttribArray(@shaderProgram.vertexPositionAttribute);

    @shaderProgram.vertexNormalAttribute = gl.getAttribLocation(@shaderProgram, "aVertexNormal");
    gl.enableVertexAttribArray(@shaderProgram.vertexNormalAttribute);

    @shaderProgram.textureCoordAttribute = gl.getAttribLocation(@shaderProgram, "aTextureCoord");
    gl.enableVertexAttribArray(@shaderProgram.textureCoordAttribute);

    @shaderProgram.pMatrixUniform = gl.getUniformLocation(@shaderProgram, "uPMatrix");
    @shaderProgram.mvMatrixUniform = gl.getUniformLocation(@shaderProgram, "uMVMatrix");
    @shaderProgram.nMatrixUniform = gl.getUniformLocation(@shaderProgram, "uNMatrix");
    @shaderProgram.samplerUniform = gl.getUniformLocation(@shaderProgram, "uSampler");
    @shaderProgram.useLightingUniform = gl.getUniformLocation(@shaderProgram, "uUseLighting");
    @shaderProgram.ambientColorUniform = gl.getUniformLocation(@shaderProgram, "uAmbientColor");
    @shaderProgram.lightingDirectionUniform = gl.getUniformLocation(@shaderProgram, "uLightingDirection");
    @shaderProgram.directionalColorUniform = gl.getUniformLocation(@shaderProgram, "uDirectionalColor");

  gl.handleLoadedTexture = (texture) ->
    gl.pixelStorei(gl.UNPACK_FLIP_Y_WEBGL, true);

    gl.bindTexture(gl.TEXTURE_2D, texture);
    gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, gl.RGBA, gl.UNSIGNED_BYTE, texture.image);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR_MIPMAP_NEAREST);
    gl.generateMipmap(gl.TEXTURE_2D);

    gl.bindTexture(gl.TEXTURE_2D, null);

  gl.loadIdentity= ->
    @mvMatrix = Matrix.I(4);
    @setMatrixUniforms()

  gl.multMatrix= (m) ->
    @mvMatrix = @mvMatrix.x(m);

  gl.mvTranslate= (v) ->
    @multMatrix(Matrix.Translation($V([v[0], v[1], v[2]])).ensure4x4());

  gl.setMatrixUniforms= ->
    pUniform = gl.getUniformLocation(@shaderProgram, "uPMatrix");
    gl.uniformMatrix4fv(pUniform, false, new Float32Array(@perspectiveMatrix.flatten()));
    mvUniform = gl.getUniformLocation(@shaderProgram, "uMVMatrix");
    gl.uniformMatrix4fv(mvUniform, false, new Float32Array(@mvMatrix.flatten()));

  gl.mvPushMatrix= (m) ->
    if (m)
      @mvMatrixStack.push(m.dup());
      @mvMatrix = m.dup();
    else
      @mvMatrixStack.push(@mvMatrix.dup());

  gl.mvPopMatrix= ->
      if (!@mvMatrixStack.length)
        throw("Can't pop from an empty matrix stack.")

      @mvMatrix = @mvMatrixStack.pop();
      return @mvMatrix;

  gl.mvRotate= (angle, v) ->
      inRadians = angle * Math.PI / 180.0;

      m = Matrix.Rotation(inRadians, $V([v[0], v[1], v[2]])).ensure4x4();
      gl.multMatrix(m);

  gl.normalMatrix = ->
    normMatrix = gl.mvMatrix.inverse()
    normMatrix = normMatrix.transpose()
    nUniform   = gl.getUniformLocation(@shaderProgram, "uNormalMatrix");
    gl.uniformMatrix4fv(nUniform, false, new WebGLFloatArray(normMatrix.flatten()));

  window.walker = new window.walker_object

