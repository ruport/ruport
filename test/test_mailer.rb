require "test/unit"
require "ruport"
begin; require "rubygems"; rescue LoadError; nil end

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
  
  def test_select_mailer
    mailer = Ruport::Mailer.new :default
    assert_mailer_equal @default_opts, mailer

    mailer.select_mailer :other
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

  # def test_html
 #    @default_mailer.instance_eval "@mail.html = 'RuportDay!'"
 #    assert_equal 'RuportDay!', @default_mailer.html
 #  end
 # 
 #  def test_html_equals
 #    @default_mailer.html = 'RuportDay!'
 #    assert_equal 'RuportDay!', @default_mailer.html
 #  end
 # 
 #  def test_text
 #    @default_mailer.instance_eval "@mail.text = 'RuportDay!'"
 #    assert_equal 'RuportDay!', @default_mailer.text
 #  end
 # 
 #  def test_text_equals
 #    @default_mailer.text = 'RuportDay!'
 #    assert_equal 'RuportDay!', @default_mailer.text
 #  end


  
end

