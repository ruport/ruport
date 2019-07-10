# frozen_string_literal: true

require File.join(File.expand_path(File.dirname(__FILE__)), "helpers")

class TestRenderMarkdownTable < Minitest::Test
  def test_render_markdown_table_basic
    actual = Ruport::Controller::Table.render_markdown do |r|
      r.data = Ruport::Table([:foo, :bar, :baz], data: [[1, 2, 3], [], [4, 5], [6]])
    end

    assert_equal([
      "|foo|bar|baz|\n",
      "|:--|:--|:--|\n",
      "|1|2|3|\n",
      "||||\n",
      "|4|5||\n",
      "|6|||\n"
    ].join, actual)
  end

  def test_render_markdown_table_without_column_names
    actual = Ruport::Controller::Table.render_markdown do |r|
      r.data = Ruport::Table(data: [[:foo, :bar], [1, 2], [3, 4]])
    end

    assert_equal([
      "|foo|bar|\n",
      "|:--|:--|\n",
      "|1|2|\n",
      "|3|4|\n",
    ].join, actual)

    actual = Ruport::Controller::Table.render_markdown do |r|
      r.data = Ruport::Table([], data: [[:foo, :bar], [1, 2], [3, 4]])
    end

    assert_equal([
      "|foo|bar|\n",
      "|:--|:--|\n",
      "|1|2|\n",
      "|3|4|\n",
    ].join, actual)
  end

  def test_escape_virtical_bar
    actual = Ruport::Controller::Table.render_markdown do |r|
      r.data = Ruport::Table([:foo], data: [['foo0|foo1']])
    end

    assert_equal([
      "|foo|\n",
      "|:--|\n",
      "|foo0&#124;foo1|\n"
    ].join, actual)
  end

  def test_escape_newline_code
    actual = Ruport::Controller::Table.render_markdown do |r|
      r.data = Ruport::Table([:foo], data: [["foo0\nfoo1"]])
    end

    assert_equal([
      "|foo|\n",
      "|:--|\n",
      "|foo0<br>foo1|\n"
    ].join, actual)
  end

  def test_alignment_option
    actual = Ruport::Controller::Table.render_markdown(alignment: :left) do |r|
      r.data = Ruport::Table([:foo, :bar], data: [[1, 2], [3, 4]])
    end

    assert_equal([
      "|foo|bar|\n",
      "|:--|:--|\n",
      "|1|2|\n",
      "|3|4|\n"
    ].join, actual)

    actual = Ruport::Controller::Table.render_markdown(alignment: :center) do |r|
      r.data = Ruport::Table([:foo, :bar], data: [[1, 2], [3, 4]])
    end

    assert_equal([
      "|foo|bar|\n",
      "|:-:|:-:|\n",
      "|1|2|\n",
      "|3|4|\n"
    ].join, actual)

    actual = Ruport::Controller::Table.render_markdown(alignment: :right) do |r|
      r.data = Ruport::Table([:foo, :bar], data: [[1, 2], [3, 4]])
    end

    assert_equal([
      "|foo|bar|\n",
      "|--:|--:|\n",
      "|1|2|\n",
      "|3|4|\n"
    ].join, actual)
  end

  def test_column_alignments_option
    actual = Ruport::Controller::Table.render_markdown(
      column_alignments: { foo: :left, bar: :right, baz: :center }
    ) do |r|
      r.data = Ruport::Table([:foo, :bar, :baz, :qux], data: [[1, 2, 3, 4], [5, 6, 7, 8]])
    end

    assert_equal([
      "|foo|bar|baz|qux|\n",
      "|:--|--:|:-:|:--|\n",
      "|1|2|3|4|\n",
      "|5|6|7|8|\n"
    ].join, actual)
  end

  def test_options_hash_override_template
    Ruport::Formatter::Template.create(:a_template) do |format|
      format.table = {
        alignment: :center,
        column_alignments: { foo: :right }
      }
    end

    actual = Ruport::Controller::Table.render_markdown(
      template: :a_template,
      alignment: :right,
      column_alignments: { foo: :left, bar: :center }
    ) do |r|
      r.data = Ruport::Table([:foo, :bar, :baz], data: [[1, 2, 3], [4, 5, 6]])
    end

    assert_equal([
      "|foo|bar|baz|\n",
      "|:--|:-:|--:|\n",
      "|1|2|3|\n",
      "|4|5|6|\n"
    ].join, actual)
  end
end
