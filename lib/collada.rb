class Collada

  attr_reader :doc, :filename

  def initialize(filename, doc)
    @filename = filename
    @doc = doc
  end

  def dir
    Pathname(File.dirname(filename))
  end

  def as_json
    {
      geometries: geometries,
      textures: Hash[textures]
    }
  end

  def geometries
    doc.css("instance_geometry").select { |in_geo|
      url = in_geo[:url]
      doc.css("#{url} triangles input[semantic=TEXCOORD]").first
    }.map do |in_geo|
      url = in_geo[:url]
      {
        indices: indices(url),
        vertices: vertices(url),
        texcoords: texcoords(url),
        material: material(in_geo)
      }
    end
  end

  def indices(url)
    doc.css("#{url} triangles p").first.content.split(/\s+/).select.with_index { |p, i| i.odd? }.map(&:to_i)
  end

  def vertices(url)
    vertex_url = doc.css("#{url} triangles input[semantic=VERTEX]").first[:source]
    {
      positions: positions(vertex_url),
      normals: normals(vertex_url)
    }
  end

  def positions(url)
    get_vertex(url, "POSITION")
  end


  def normals(url)
    get_vertex(url, "NORMAL")
  end

  def get_vertex(url, semantic)
    source_url = doc.css("#{url} input[semantic=#{semantic}]").first[:source]
    doc.css("#{source_url} float_array").first.content.split(/\s+/).map(&:to_f)
  end

  def texcoords(url)
    source = doc.css("#{url} triangles input[semantic=TEXCOORD]").first
    if source
      source_url = source[:source]
      doc.css("#{source_url} float_array").first.content.split(/\s+/).map(&:to_f)
    end
  end

  def material(in_geo)
    material_id = in_geo.css("bind_material instance_material").first[:target]
    effect_id = doc.css("#{material_id} instance_effect").first[:url]
    color_doc = doc.css("#{effect_id} color")
    if color_doc.any?
      {
        color: color_doc.first.content.split(/\s+/).map(&:to_f),
        texture: nil
      }
    else
      image_id  = doc.css("#{effect_id} init_from").first.content
      filename = doc.css("##{image_id} init_from").first.content
      {
        texture: md5(filename),
        color: [1,1,1,1]
      }
    end
  end

  def textures
    doc.css("library_images image init_from").map do |init_from|
      [md5(init_from.content), init_from.content ]
    end
  end

  def md5(filename)
    data = File.open(dir.join(filename), 'rb').read
    Digest::MD5.hexdigest(data)
  end

end
