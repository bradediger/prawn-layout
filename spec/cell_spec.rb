# encoding: utf-8

require File.join(File.expand_path(File.dirname(__FILE__)), "spec_helper")  

module CellHelpers

  # Build, but do not draw, a cell on @pdf.
  # TODO: differentiate class based on :content.
  def cell(options={})
    at = options[:at] || [0, @pdf.cursor]
    Prawn::Table::Cell::Text.new(@pdf, at, options)
  end

  def close?(actual, expected, epsilon=0.01)
    (actual - expected).abs < epsilon
  end

end

describe "Prawn::Table::Cell" do
  before(:each) do
    @pdf = Prawn::Document.new
  end

  describe "Prawn::Document#cell" do
    include CellHelpers

    it "should draw the cell" do
      Prawn::Table::Cell::Text.any_instance.expects(:draw).once
      @pdf.cell(:content => "text")
    end

    it "should return a Cell" do
      @pdf.cell(:content => "text").should.be.a.kind_of Prawn::Table::Cell
    end

    it "should draw text at the given point plus padding, with the given " +
       "size and style" do
      @pdf.expects(:bounding_box).with{ |at, options| 
        at == [50, -10] && 
          close?(options[:height], 8.33) && 
          close?(options[:width], 36.953)
      }.yields
      @pdf.expects(:move_down).with{ |x| close?(x, 1.652) }
      @pdf.expects(:text).with("hello world")

      @pdf.cell(:content => "hello world", 
                :at => [10, 20],
                :padding => [30, 40],
                :font_size => 7, 
                :font_style => :bold)
    end
  end

  describe "cell width" do
    include CellHelpers

    it "should be calculated for text" do
      c = cell(:content => "text")
      c.width.should == @pdf.width_of("text")
    end

    it "should be overridden by manual :width" do
      c = cell(:content => "text", :width => 400)
      c.width.should == 400
    end

    it "should incorporate padding when specified" do
      c = cell(:content => "text", :padding => [1, 2, 3, 4])
      c.width.should.be.close(@pdf.width_of("text") + 6, 0.01)
    end

    it "should allow width to be reset after it has been calculated" do
      # to ensure that if we memoize width, it can still be overridden
      c = cell(:content => "text")
      c.width
      c.width = 400
      c.width.should == 400
    end

    it "should return proper width with font_size set" do
      text = "text " * 4
      c = cell(:content => text, :font_size => 7)
      c.width.should == @pdf.width_of(text, :size => 7)
    end

    it "content_width should exclude padding" do
      c = cell(:content => "text", :padding => 10)
      c.content_width.should == @pdf.width_of("text")
    end

    it "content_width should exclude padding even with manual :width" do
      c = cell(:content => "text", :padding => 10, :width => 400)
      c.content_width.should.be.close(380, 0.01)
    end

  end

  describe "cell height" do
    include CellHelpers

    it "should be calculated for text" do
      c = cell(:content => "text")
      c.height.should == @pdf.height_of("text", :width => @pdf.width_of("text"))
    end

    it "should be overridden by manual :height" do
      c = cell(:content => "text", :height => 400)
      c.height.should == 400
    end

    it "should incorporate :padding when specified" do
      c = cell(:content => "text", :padding => [1, 2, 3, 4])
      c.height.should.be.close(1 + 3 +
        @pdf.height_of("text", :width => @pdf.width_of("text")), 0.01)
    end

    it "should allow height to be reset after it has been calculated" do
      # to ensure that if we memoize height, it can still be overridden
      c = cell(:content => "text")
      c.height
      c.height = 400
      c.height.should == 400
    end

    it "should return proper height for blocks of text" do
      content = "words " * 10
      c = cell(:content => content, :width => 100)
      c.height.should == @pdf.height_of(content, :width => 100)
    end

    it "should return proper height for blocks of text with font_size set" do
      content = "words " * 10
      c = cell(:content => content, :width => 100, :font_size => 7)

      correct_height = nil
      @pdf.font_size(7) do
        correct_height = @pdf.height_of(content, :width => 100)
      end

      c.height.should == correct_height
    end

    it "content_height should exclude padding" do
      c = cell(:content => "text", :padding => 10)
      c.content_height.should == @pdf.height_of("text")
    end
    
    it "content_height should exclude padding even with manual :height" do
      c = cell(:content => "text", :padding => 10, :height => 400)
      c.content_height.should.be.close(380, 0.01)
    end
  end

  describe "cell padding" do
    include CellHelpers

    it "should default to zero" do
      c = cell(:content => "text")
      c.padding.should == [0, 0, 0, 0]
    end

    it "should accept a numeric value, setting all padding" do
      c = cell(:content => "text", :padding => 10)
      c.padding.should == [10, 10, 10, 10]
    end

    it "should accept [v,h]" do
      c = cell(:content => "text", :padding => [20, 30])
      c.padding.should == [20, 30, 20, 30]
    end

    it "should accept [t,l,b,r]" do
      c = cell(:content => "text", :padding => [10, 20, 30, 40])
      c.padding.should == [10, 20, 30, 40]
    end

    it "should reject other formats" do
      lambda{
        cell(:content => "text", :padding => [10])
      }.should.raise(ArgumentError)
    end
  end


  describe "Borders" do
    it "should draw all borders by default" do
      @pdf.expects(:stroke_line).times(4)
      @pdf.cell(:content => "text")
    end

    it "should draw all borders when requested" do
      @pdf.expects(:stroke_line).times(4)
      @pdf.cell(:content => "text", :borders => [:top, :right, :bottom, :left])
    end

    # Only roughly verifying the integer coordinates so that we don't have to
    # do any FP closeness arithmetic. Can plug in that math later if this goes
    # wrong.
    it "should draw top border when requested" do
      @pdf.expects(:stroke_line).with { |*from_and_to|
        #                                  from: x  y to: x  y
        from_and_to.flatten.map{|x| x.round} == [0, 720, 19, 720]
      }
      @pdf.cell(:content => "text", :borders => [:top])
    end

    it "should draw bottom border when requested" do
      @pdf.expects(:stroke_line).with { |*from_and_to|
        from_and_to.flatten.map{|x| x.round} == [0, 706, 19, 706]
      }
      @pdf.cell(:content => "text", :borders => [:bottom])
    end

    it "should draw left border when requested" do
      @pdf.expects(:stroke_line).with { |*from_and_to|
        from_and_to.flatten.map{|x| x.round} == [0, 720, 0, 706]
      }
      @pdf.cell(:content => "text", :borders => [:left])
    end

    it "should draw right border when requested" do
      @pdf.expects(:stroke_line).with { |*from_and_to|
        from_and_to.flatten.map{|x| x.round} == [19, 720, 19, 706]
      }
      @pdf.cell(:content => "text", :borders => [:right])
    end
  end

  describe "Font handling" do
    include CellHelpers

    it "should allow only :font_style to be specified, defaulting to the" +
       "document's font" do
      c = cell(:content => "text", :font_style => :bold)
      c.font.name.should == 'Helvetica-Bold'
    end

    it "should accept a Prawn::Font for :font" do
      font = @pdf.find_font('Helvetica-Bold')
      c = cell(:content => "text", :font => font)
      c.font.should == font
    end

    it "should accept a font name for :font" do
      c = cell(:content => "text", :font => 'Helvetica-Bold')
      c.font.name.should == 'Helvetica-Bold'
    end

    it "should default to the document's font, if none is specified" do
      c = cell(:content => "text")
      c.font.should == @pdf.font
    end

    it "should use the metrics of the selected font (even if it is a variant " +
       "of the document's font) to calculate width" do
      c = cell(:content => "text", :font_style => :bold)
      font = @pdf.find_font('Helvetica-Bold')
      c.content_width.should == font.compute_width_of("text")
    end
  end

end