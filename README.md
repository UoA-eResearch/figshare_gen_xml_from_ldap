# figshare_gen_xml_from_ldap
Reads the UoA LDAP and generates an XML HR file to upload to Figshare.

conf/academic_department_code_to_faculty.json maps academic department codes the department's faculty.

* There are a few departments in more than one faculty, so the primary one has been chosen.
* Also note that there are many non-academic department codes that get mapped to nil.
    
conf/course_codes_to_faculty.json maps student course codes (papers) to a faculty

* There are conflicts here too, so a primary faculty was chosen for each course.

conf/override_group.json is a list of people we want in specific groups, regardless of the LDAP grouping.
 
* A null group is "" in this file, where in the others, it is null

Just execute:
```
  run.rb
```
and get a new XML file in the user_xml_files/ directory, called figshare_hr_feed_Year-Month-Day.xml
This xml file's name is also put into Upload/hr_file_to_upload.json, so Upload/upload.py can just be run.

conf/auth.json is for accessing the LDAP
```
{
  "username": "login_name",     // a user w/sufficient privileges to read from AD goes here,
  "password": "the_password"    // the user's password goes here 
}
```
conf/figshare_hr_key.json holds the API key generated through the application menu on figshare.com
We set up a dummy user in figshare, with admin rights, and assigned this key to the Hr Figshare user.
```
{
  "hr_figshare_token": "xxxxxxxxxxxxxxxxxxxx..."
}
```


Figshare XML is of the form
```
<?xml version=\"1.0\" encoding=\"utf-8\"?>
<HRFeed>
  <Record>
     <UniqueID>aaaa001@auckland.ac.nz</UniqueID>
     <FirstName>Aaa</FirstName>
     <LastName>Aaa Home Test</LastName>
     <Email></Email>
     <IsActive>y</IsActive>
     <UserQuota>10737418240</UserQuota>
     <UserAssociationCriteria>dummy</UserAssociationCriteria>
     <SymplecticUniqueID>4642721</SymplecticUniqueID>
  </Record>
...
</HRFeed>
```

A null UserAssociationCriteria adds the user in at the UoA level of the Figshare hierarchy. I have set this field to null for anyone in multiple faculty, and for all non-academic staff.

There are test versions of upload.py, with associated test keys, that talk to auckland.figsh.com.

##Ubuntu

Installing on Ubuntu, where python and ruby are packaged, I had to 
```
 apt-get install ruby-net-ldap
 apt-get install python-requests
```
Also added figshare user to system and set up cron as that user.
```
adduser --system  --disabled-password --shell /bin/sh --group figshare figshare
```




