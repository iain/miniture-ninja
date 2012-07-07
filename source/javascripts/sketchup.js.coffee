class Pillar
  draw: ->
    # @drawObject(data) for data in @data
    # @drawObject(@data[0])

  buffer: ->
    # @data    = window.loaded_objects.scene
    # @textures = window.loaded_objects.textures

    # @initTextures()
    # console.log(@textures)
    # @bufferObject(data) for data in @data

  drawObject: (data) ->
    gl.bindBuffer(gl.ARRAY_BUFFER, data.vertexPositionBuffer);
    gl.vertexAttribPointer(gl.shaderProgram.vertexPositionAttribute, 3, gl.FLOAT, false, 0, 0);

    gl.bindBuffer(gl.ARRAY_BUFFER, data.vertexNormalBuffer);
    gl.vertexAttribPointer(gl.shaderProgram.vertexNormalAttribute, 3, gl.FLOAT, false, 0, 0);

    gl.bindBuffer(gl.ARRAY_BUFFER, data.vertexTextureCoordBuffer);
    gl.vertexAttribPointer(gl.shaderProgram.textureCoordAttribute, 2, gl.FLOAT, false, 0, 0);

    gl.activeTexture(gl.TEXTURE0);
    gl.bindTexture(gl.TEXTURE_2D, @textureBuffers[data.material.texture]);
    gl.uniform1i(gl.shaderProgram.samplerUniform, 0);

    lighting = true

    gl.uniform1i(gl.shaderProgram.useLightingUniform, lighting); # set to true if lighting is enabled

    #lighting stuff will go here
    if (lighting)
      gl.uniform3f( gl.shaderProgram.ambientColorUniform,0.2,0.2,0.2)

      lightingDirection = [-0.25, -0.25,-1.0]

      adjustedLD = vec3.create()
      vec3.normalize(lightingDirection, adjustedLD)
      vec3.scale(adjustedLD, -1)
      gl.uniform3fv(gl.shaderProgram.lightingDirectionUniform, adjustedLD)

      gl.uniform3f( gl.shaderProgram.directionalColorUniform, 0.8, 0.8, 0.8)

    gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, data.vertexIndexBuffer);
    gl.setMatrixUniforms();
    gl.drawElements(gl.TRIANGLES, data.geometry.indices.length, gl.UNSIGNED_SHORT, 0);



  bufferObject: (data) ->
    data.vertexPositionBuffer = gl.createBuffer()
    gl.bindBuffer(gl.ARRAY_BUFFER, data.vertexPositionBuffer)
    gl.bufferData(gl.ARRAY_BUFFER, new Float32Array(data.geometry.vertices), gl.STATIC_DRAW)

    data.vertexNormalBuffer = gl.createBuffer();
    gl.bindBuffer(gl.ARRAY_BUFFER, data.vertexNormalBuffer);
    gl.bufferData(gl.ARRAY_BUFFER, new Float32Array(data.geometry.normals), gl.STATIC_DRAW);

    data.vertexTextureCoordBuffer = gl.createBuffer();
    gl.bindBuffer(gl.ARRAY_BUFFER, data.vertexTextureCoordBuffer);
    gl.bufferData(gl.ARRAY_BUFFER, new Float32Array(data.geometry.texcoords), gl.STATIC_DRAW);

    data.vertexIndexBuffer = gl.createBuffer()
    gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, data.vertexIndexBuffer)
    gl.bufferData(gl.ELEMENT_ARRAY_BUFFER, new Uint16Array(data.geometry.indices), gl.STATIC_DRAW)

  initTextures:() ->
    @textureBuffers = []
    for texture in @textures
      @textureBuffers[@textureBuffers.length] = @initTexture(texture["src"])


  initTexture:(src) ->
    texture = gl.createTexture();
    texture.image = new Image();
    texture.image.src = src
    texture.image.onload = @hmm(texture)
    return texture

  hmm: (texture) ->
    gl.handleLoadedTexture(texture)

window.pillar = Pillar

