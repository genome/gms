use strict;
use warnings;
use Genome;
use Getopt::Long;

sub usage {
  print "
perl add_user.pl
Arguments:
  --username  Username of the user [pwuid]
  --name      Name of the user [username]
  --email     Email of the user [username\@temp.com]
";
  exit();
}

#get info for current user
sub get_user_info {
  my ($name, $username, $email);
  GetOptions (
    'name=s'=>\$name,
    'username=s'=>\$username,
    'email=s'=>\$email,
    'help'=>\&usage
  );
  $username //= getpwuid($<);
  $name //= $username;
  $email //= $username . "\@temp.com";
  printf "\nFound user: %s\t%s\t%s", $name, $username, $email;
  return ($name, $username, $email);
}

#create a role called admin
sub create_admin_role {
  print "\nCreating role admin";
  my $dbh = Genome::Sys::User::Role->__meta__->data_source->get_default_handle;
  my $sth = $dbh->prepare('INSERT INTO subject.role (id, name) VALUES (?,?)');
  $sth->execute("4AAB87D4743D11E1AD77BD4F3B8842A7", "admin");
}

#add a new user
sub add_user {
  my $name = shift;
  my $email = shift;
  my $username = shift;
  print "\nAdding user $username";
  my $dbh = Genome::Sys::User->__meta__->data_source->get_default_handle;
  my $sth = $dbh->prepare('INSERT INTO subject.user (name, email, username) VALUES (?,?,?)');
  $sth->execute($name, $email, $username);
}

#assign role to user
sub assign_role_user {
  my $role = shift;
  my $email = shift;
  print "\nMaking user $email into role $role";
  my $role_id = Genome::Sys::User::Role->get(name => $role)->id;
  my $dbh = Genome::Sys::User::RoleMember->__meta__->data_source->get_default_handle;
  my $sth = $dbh->prepare('INSERT INTO subject.role_member (user_email, role_id) VALUES (?,?)');
  $sth->execute($email, $role_id);
}

sub main {
  create_admin_role();
  my ($name, $username, $email) = get_user_info();
  add_user($name, $email, $username);
  add_user("Genome", "genome\@temp.com", "genome");
  assign_role_user("admin", "genome\@temp.com");
}

main();
