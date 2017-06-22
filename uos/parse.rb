require 'json'

def load_json_file(filename)
  JSON.parse(File.read(filename))
end

OUTPUT_FILE = "../conf/academic_department_code_to_faculty.json"
INPUT_LOCATOR = "uos_location.json"

@uos_filename = load_json_file("uos_location.json")

#Tab separated file saved from UoS xls file, and comment line (first line) removed.

@uos = {}
File.open(@uos_filename['uos_file'], 'r') do |fd|
  #!Note, Excel, on my Mac OS X 10.9 system, saved csv with CRs, not LFs.
  fd.each_line(sep="\r") do |l|
    if l.chomp! != ''
      node, descr, uoa_descr, parent = l.split("\t")
      uoa_descr = uoa_descr[1..-2] if uoa_descr[0,1] == '"' 
      @uos[node] = {:node => node, :descr => uoa_descr, :parent => parent}
    end
  end
end

#UoS node names that should match to a Faculty
@faculty = load_json_file("faculty.json")


def find_faculty(node)
  return @faculty[node[:node]] if @faculty[node[:node]] != nil
  return @faculty[node[:parent]] if @faculty[node[:parent]] != nil
  return nil if @uos[node[:parent]] == nil #Has no parent.
  return find_faculty( @uos[ node[:parent] ] ) 
end

@flat_uos = {}
@uos.each do |node, attributes|
  @flat_uos[node] = {:faculty => find_faculty(attributes), :descr => attributes[:descr]}
end

File.open(OUTPUT_FILE, "w+") do |fd|
  fd.puts "{"
  @flat_uos.sort.each do |node, attributes|
    if attributes[:faculty] != nil
      fd.puts "  \"#{"%-15s" % (node + '":') } { \"faculty\": #{ "%12s" % ('"' + attributes[:faculty] + '"') }, \"descr\":   \"#{attributes[:descr]}\" },"
    else
      fd.puts "  \"#{"%-15s" % (node + '":') } { \"faculty\": #{"%12s" % ("null") }, \"descr\":   \"#{attributes[:descr]}\" },"
    end
  end
  #Couple in the LDAP, that don't look to be in the UoS
  ['MAIDMENT', 'OUTREACH'].each do |s|
    fd.puts "  \"#{"%-15s" % ("#{s}\":") } { \"faculty\": #{"%12s" % "null"}, \"descr\":   \"#{s}\" }," if @flat_uos[s] == nil
  end
  fd.puts "  \"#{"%-15s" % ('EOT":') } { \"faculty\": #{"%12s" % "null"}, \"descr\":   \"End of Text\" }"
  fd.puts "}"
end
  
