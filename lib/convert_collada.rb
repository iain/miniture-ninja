# encoding: utf-8
require 'bundler/setup'
Bundler.setup

require 'nokogiri'
require 'json'
require 'digest'
require 'pathname'

module ConvertCollada

  def self.convert(filename)
    contents = File.open(filename, 'r:utf-8').read
    doc = Nokogiri::XML(contents)
    collada = Collada.new(filename, doc)
    puts collada.to_json
  end

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
      { geometries: geometries,
        textures: Hash[textures] }
    end

    def geometries
      doc.css("library_visual_scenes visual_scene node instance_geometry").map do |in_geo|
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
      source_url = doc.css("#{url} triangles input[semantic=TEXCOORD]").first[:source]
      doc.css("#{source_url} float_array").first.content.split(/\s+/).map(&:to_f)
    end

    def material(in_geo)
      material_id = in_geo.css("bind_material instance_material").first[:target]
      effect_id = doc.css("#{material_id} instance_effect").first[:url]
      image_id  = doc.css("#{effect_id} init_from").first.content
      filename = doc.css("##{image_id} init_from").first.content
      {texture: md5(filename)}
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


    def to_json
      JSON.pretty_generate(as_json)
    end

  end

end

ConvertCollada.convert(ARGV.first)
