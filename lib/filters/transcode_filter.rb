require 'popen4'

# Uses ffmpeg to transcode a video into h.264 and MP4box to interleave
# the metadata for fast playback and streaming.
class TranscodeFilter < Nanoc3::Filter
  identifier :transcode
  type :binary

  def run(filename, params={})
    width = params[:width] || 480
    height = params[:height] || 320
    bitrate = params[:bitrate] || '400k'
    audio_bitrate = params[:audio_bitrate] || '64k'
    title = @item[:title] || filename
   
    intermediate_filename = output_filename + '.mp4'

    # Create iPod/iPhone compatible h.264 video
    command = [
      'ffmpeg',
      '-i','"' + filename + '"',
      '-acodec','libfaac',
      '-ab',audio_bitrate,
      '-s',"#{width}x#{height}",
      '-vcodec', 'libx264',
      '-vpre', 'hq', 
      '-vpre', 'ipod320',
      '-b', bitrate,
      '-bt', bitrate,
      '-metadata', "\"title=#{title}\"",
      '-threads', '0',
      '-f', 'ipod',
      '"' + intermediate_filename + '"'
    ].join(' ')

    output = ''
    error = ''
    status = POpen4::popen4(command) do |stdout,stderr,stdin,pid|
      output = stdout.read.strip
      err = stderr.read.strip
    end
    if status != 0
      raise "Error running ffmpeg: #{command} - #{error}"
    end

    # Interleave the metadata to support fast playback and seeking.
    command = "MP4Box -inter 500 -hint #{intermediate_filename}"
    status = POpen4::popen4(command) do |stdout,stderr,stdin,pid|
      output = stdout.read.strip
      err = stderr.read.strip
    end
    raise "Error running MP4Box: #{command} - #{error}" unless status == 0

    `mv "#{intermediate_filename}" "#{output_filename}"`
  end
end
