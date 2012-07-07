class Sketchup
  constructor: ->
    @textureBuffers = {}
    @buffered = false

  draw: ->
    if @buffered
      @drawObject(geometry) for geometry in @data.geometries

  buffer: ->
    $.getJSON("models/cubism.json?_#{(new Date).getTime()}", @handleData )
    # @data    = window.loaded_objects.scene
    # @textures = window.loaded_objects.textures

    # @initTextures()
    # console.log(@textures)
    
  handleData: (data) =>
    @data = data
    @initTextures(data.textures)
    @bufferObject(geometry) for geometry in data.geometries
    @buffered = true

  drawObject: (data) ->
    gl.bindBuffer(gl.ARRAY_BUFFER, data.vertexPositionBuffer)
    gl.vertexAttribPointer(gl.shaderProgram.vertexPositionAttribute, 3, gl.FLOAT, false, 0, 0)

    gl.bindBuffer(gl.ARRAY_BUFFER, data.vertexNormalBuffer)
    gl.vertexAttribPointer(gl.shaderProgram.vertexNormalAttribute, 3, gl.FLOAT, false, 0, 0)

    gl.bindBuffer(gl.ARRAY_BUFFER, data.vertexTextureCoordBuffer)
    gl.vertexAttribPointer(gl.shaderProgram.textureCoordAttribute, 2, gl.FLOAT, false, 0, 0)

    gl.activeTexture(gl.TEXTURE0)
    gl.bindTexture(gl.TEXTURE_2D, @textureBuffers[data.material.texture])
    gl.uniform1i(gl.shaderProgram.samplerUniform, 0)

    lighting = true

    gl.uniform1i(gl.shaderProgram.useLightingUniform, lighting) # set to true if lighting is enabled

    #lighting stuff will go here
    if (lighting)
      gl.uniform3f( gl.shaderProgram.ambientColorUniform,0.2,0.2,0.2)

      lightingDirection = [-0.25, -0.25,-1.0]

      adjustedLD = vec3.create()
      vec3.normalize(lightingDirection, adjustedLD)
      vec3.scale(adjustedLD, -1)
      gl.uniform3fv(gl.shaderProgram.lightingDirectionUniform, adjustedLD)

      gl.uniform3f( gl.shaderProgram.directionalColorUniform, 0.8, 0.8, 0.8)

    gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, data.vertexIndexBuffer)
    gl.setMatrixUniforms()
    gl.drawElements(gl.TRIANGLES, data.indices.length, gl.UNSIGNED_SHORT, 0)



  bufferObject: (geometry) ->
    geometry.vertexPositionBuffer = gl.createBuffer()
    gl.bindBuffer(gl.ARRAY_BUFFER, geometry.vertexPositionBuffer)
    gl.bufferData(gl.ARRAY_BUFFER, new Float32Array(geometry.vertices.positions), gl.STATIC_DRAW)

    geometry.vertexNormalBuffer = gl.createBuffer()
    gl.bindBuffer(gl.ARRAY_BUFFER, geometry.vertexNormalBuffer)
    gl.bufferData(gl.ARRAY_BUFFER, new Float32Array(geometry.vertices.normals), gl.STATIC_DRAW)

    geometry.vertexTextureCoordBuffer = gl.createBuffer()
    gl.bindBuffer(gl.ARRAY_BUFFER, geometry.vertexTextureCoordBuffer)
    gl.bufferData(gl.ARRAY_BUFFER, new Float32Array(geometry.texcoords), gl.STATIC_DRAW)

    geometry.vertexIndexBuffer = gl.createBuffer()
    gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, geometry.vertexIndexBuffer)
    gl.bufferData(gl.ELEMENT_ARRAY_BUFFER, new Uint16Array(geometry.indices), gl.STATIC_DRAW)

  initTextures:(textures) ->
    for md5, src of textures
      @textureBuffers[md5] = @initTexture("/models/#{src}")

  initTexture:(src) ->
    texture = gl.createTexture()
    texture.image = new Image()
    texture.image.src = src
    texture.image.onload = => @handleLoadedTexture(texture)
    return texture

  handleLoadedTexture: (texture) ->
    gl.handleLoadedTexture(texture)

window.Sketchup = Sketchup
