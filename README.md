# figshare_gen_xml_from_ldap
Reads the UoA LDAP and generates an XML HR file to upload to Figshare.

conf/academic_department_code_to_faculty.json maps academic department codes the department's faculty. 
**Nb. There are a few departments in more than one faculty, so the primary one has been chosen.**
**&nbsp;&nbsp;&nbsp;&nbsp;Also note that there are many non-academic department codes that get mapped to nil.**
    
conf/course_codes_to_faculty.json maps student course codes (papers) to a faculty
**Nb. There are conflicts here too, so a primary faculty was chosen for each course.**

Just execute 
```
  run.rb
```

conf/auth.json is of form
```
{
  "username": "login_name",     // a user w/sufficient privileges to read from AD goes here,
  "password": "the_password"    // the user's password goes here 
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

