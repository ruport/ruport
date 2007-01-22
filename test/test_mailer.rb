require "test/unit"
require "ruport"
begin; require "rubygems"; rescue LoadError; nil end

begin
  require 'mocha'
  require 'stubba'
  require 'net/smtp'
rescue LoadError
  $stderr.puts "Warning: Mocha not found -- skipping some Mailer tests"
end

class TestMailer < Test::Unit::TestCase

  def setup
    @default_opts = {
      :host => "mail.example.com", 
      :address => "sue@example.com", 
      :user => "inky",
      :password => "chunky"
    }

    @other_opts = {
      :host => "moremail.example.com",
      :address => "clyde@example.com",
      :user => "blinky",
      :password => "bacon"
    }

    Ruport::Config.mailer :default, @default_opts
    Ruport::Config.mailer :other, @other_opts

    @default_mailer = Ruport::Mailer.new
    @other_mailer = Ruport::Mailer.new :other 
  end
    
  def assert_mailer_equal(expected, mailer)
    assert_equal expected[:host], mailer.instance_variable_get(:@host)
    assert_equal expected[:address], mailer.instance_variable_get(:@address)
    assert_equal expected[:user], mailer.instance_variable_get(:@user)
    assert_equal expected[:password], mailer.instance_variable_get(:@password)
  end
  
  def test_default_constructor    
    assert_mailer_equal @default_opts, @default_mailer
  end
  
  def test_constructor_with_mailer_label
    assert_mailer_equal @other_opts, @other_mailer
  end

  def test_constructor_without_mailer
    Ruport::Config.mailers[:default] = nil
    assert_raise(RuntimeError) { Ruport::Mailer.new }
  end
 
  def test_select_mailer
    mailer = Ruport::Mailer.new :default
    assert_mailer_equal @default_opts, mailer

    mailer.send(:select_mailer, :other)
    assert_mailer_equal @other_opts, mailer
  end

  def test_to
    @default_mailer.instance_eval "@mail.to = ['foo@bar.com']"
    assert_equal ['foo@bar.com'], @default_mailer.to
  end

  def test_to_equals
    @default_mailer.to = ['foo@bar.com']
    assert_equal ['foo@bar.com'], @default_mailer.to    
  end

  def test_from
    @default_mailer.instance_eval "@mail.from = ['foo@bar.com']"
    assert_equal ['foo@bar.com'], @default_mailer.from
  end

  def test_from_equals
    @default_mailer.from = ['foo@bar.com']
    assert_equal ['foo@bar.com'], @default_mailer.from
  end

  def test_subject
    @default_mailer.instance_eval "@mail.subject = ['RuportDay!']"
    assert_equal ['RuportDay!'], @default_mailer.subject
  end

  def test_subject_equals
    @default_mailer.subject = ['RuportDay!']
    assert_equal ['RuportDay!'], @default_mailer.subject
  end

  def test_send_mail_with_default
    return unless Object.const_defined? :Mocha
    setup_mock_mailer(1)
    assert_equal "250 ok",
      @default_mailer.deliver(:to      => "clyde@example.com",
                              :from    => "sue@example.com",
                              :subject => "Hello",
                              :text    => "This is a test.")
  end

  def test_send_mail_with_other
    return unless Object.const_defined? :Mocha
    setup_mock_mailer(1, @other_mailer)
    assert_equal "250 ok",
      @other_mailer.deliver(:to      => "sue@example.com",
                            :from    => "clyde@example.com",
                            :subject => "Hello",
                            :text    => "This is a test.")
  end

  def test_send_mail_without_to
    return unless Object.const_defined? :Mocha
    setup_mock_mailer(1)
    assert_raise(Net::SMTPSyntaxError) {
      @default_mailer.deliver(:from    => "sue@example.com",
                              :subject => "Hello",
                              :text    => "This is a test.")
    }
  end

  def test_send_html_mail
    return unless Object.const_defined? :Mocha
    setup_mock_mailer(1)
    assert_equal "250 ok",
      @default_mailer.deliver(:to      => "clyde@example.com",
                              :from    => "sue@example.com",
                              :subject => "Hello",
                              :html    => "<p>This is a test.</p>")
  end

  def test_send_mail_with_attachment
    return unless Object.const_defined? :Mocha
    setup_mock_mailer(1)
    @default_mailer.attach 'test/samples/data.csv'
    assert_equal "250 ok",
      @default_mailer.deliver(:to      => "clyde@example.com",
                              :from    => "sue@example.com",
                              :subject => "Hello",
                              :text    => "This is a test.")
  end
  
  private
  
  def setup_mock_mailer(count, mailer=@default_mailer)
    host      = mailer.instance_variable_get(:@host)
    port      = mailer.instance_variable_get(:@port)
    user      = mailer.instance_variable_get(:@user)
    password  = mailer.instance_variable_get(:@password)
    auth      = mailer.instance_variable_get(:@auth)
    
    @smtp     = mock('smtp')
    
    Net::SMTP.expects(:start).
      with(host,port,host,user,password,auth).
      yields(@smtp).
      returns("250 ok").times(count)
    @smtp.stubs(:send_message).
      with {|*params| !params[2].nil? }.
      returns("250 ok")
    @smtp.stubs(:send_message).
      with {|*params| params[2].nil? }.
      raises(Net::SMTPSyntaxError)
  end

end

