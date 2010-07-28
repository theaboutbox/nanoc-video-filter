# Creates a Jpeg poster frame for a video
class PosterFrameFilter < Nanoc3::Filter
  identifier :poster_frame
  type :binary

  def run(filename, params={})
    width = params[:width] || 480
    height = params[:height] || 320
    filetype = params[:filetype] || 'jpg'
    title = @item[:title] || filename

    intermediate_file = output_filename + '.jpg'

    command = [
      'ffmpeg',
      '-itsoffset', '25%',
      '-i', filename,
      '-vcodec', 'mjpeg', 
      '-vframes', '1',
      '-an', 
      '-s', "#{width}x#{height}",
      '"' + intermediate_file + '"'
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

    `mv "#{intermediate_file}" "#{output_filename}"`
  end
end
