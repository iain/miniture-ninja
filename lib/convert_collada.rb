# encoding: utf-8
require 'bundler/setup'
Bundler.setup

require 'nokogiri'
require 'json'
require 'digest'
require 'pathname'
require 'fileutils'
require 'mini_magick'
require_relative 'collada'

class ConvertCollada
  include FileUtils

  def self.call(*args)
    new(*args).convert
  end

  attr_reader :filename, :destination

  def initialize(filename, destination)
    @filename = Pathname(filename)
    @destination = Pathname(destination)
  end

  def convert
    mkdir_p destination
    write_json
    copy_files
    resize_textures
  end

  # Resizing images to be a square and the dimensions to be a power of 2,
  # because WebGL doesn't support other sizes.
  # NB: this means that the key isn't the real MD5 hash anymore.
  def resize_textures
    data[:textures].each_value do |image|
      target = destination.join(image)
      image = MiniMagick::Image.open(target)
      size = [ image[:width], image[:height] ].min
      size = 2 ** Math.log(size, 2).floor
      image.resize "#{size}x#{size}!"
      image.write target.to_s
    end
  end

  def write_json
    File.open(destination.join("#{filename.basename('.dae')}.json"), 'w:utf-8') do |f|
      f.puts JSON.generate(data)
    end
  end

  def copy_files
    data[:textures].each_value do |image|
      target = destination.join(image)
      mkdir_p target.dirname
      source = filename.dirname.join(image)
      cp source, target
    end
  end

  def data
    @data ||= collada.as_json
  end

  def collada
    @collada ||= Collada.new(filename, doc)
  end

  def doc
    @doc ||= Nokogiri::XML(contents)
  end

  def contents
    @contents ||= File.open(filename, 'r:utf-8').read
  end

end
