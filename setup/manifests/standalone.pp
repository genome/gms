
$user_name = "genome"
$group_name = "genome" 

group { $group_name:
    ensure => 'present',
    gid => '2001',
}

user { $user_name:               
    home => '/home/genome',           
    password_min_age => '0',
    ensure => 'present',       
    uid => '2001',                
    #shell => '/sbin/nologin',  
    #password_max_age => '99999',    
    #password => '*',           
    gid => '2001',                
    groups => ['bin','daemon','adm','lp'], 
    comment => 'The Genome Modeling System system user'        
}

