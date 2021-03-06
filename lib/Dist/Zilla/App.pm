use strict;
use warnings;
package Dist::Zilla::App;
# ABSTRACT: Dist::Zilla's App::Cmd
use App::Cmd::Setup 0.307 -app; # need ->app in Result of Tester, GLD vers

use Carp ();
use Dist::Zilla::Config::Finder;
use File::HomeDir ();
use Moose::Autobox;
use Path::Class;

sub config {
  my ($self) = @_;

  my $homedir = File::HomeDir->my_home
    or Carp::croak("couldn't determine home directory");

  my $file = dir($homedir)->file('.dzil');
  return unless -e $file;

  if (-d $file) {
    return Dist::Zilla::Config::Finder->new->read_config({
      root     =>  dir($homedir)->subdir('.dzil'),
      basename => 'config',
    });
  } else {
    return Dist::Zilla::Config::Finder->new->read_config({
      root     => dir($homedir),
      filename => '.dzil',
    });
  }
}

sub config_for {
  my ($self, $plugin_class) = @_;

  return {} unless $self->config;

  my ($section) = grep { ($_->package||'') eq $plugin_class }
                  $self->config->sections;

  return {} unless $section;

  return $section->payload;
}

sub global_opt_spec {
  return (
    [ "verbose|v", "log additional output" ],
    [ "inc|I=s@",  "additional \@INC dirs", {
        callbacks => { 'always fine' => sub { unshift @INC, @{$_[0]}; } }
    } ]
  );
}

=method zilla

This returns the Dist::Zilla object in use by the command.  If none has yet
been constructed, one will be by calling C<< Dist::Zilla->from_config >>.

=cut

sub zilla {
  my ($self) = @_;

  require Dist::Zilla;
  require Dist::Zilla::Logger::Global;

  return $self->{__PACKAGE__}{zilla} ||= do {
    my $verbose = $self->global_options->verbose;

    my $logger = Dist::Zilla->default_logger;
    $logger->set_debug($verbose);

    my $zilla = Dist::Zilla->from_config({ logger => $logger });
    $zilla->dzil_app($self);

    $zilla->logger->set_debug($verbose);

    $zilla;
  }
}

1;
