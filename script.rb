require 'open-uri'
require 'nokogiri'
require 'csv'

class Category
  attr_accessor :count_items, :page_count

  def parse(url)
    @page_count = 25
    html = open(url)
    doc = Nokogiri::HTML(html)
    category = Item.new
    puts("Enter file name")
    file = gets.chomp
    pagination = check_pagination(doc, category)
    CSV.open(file, 'a+') do |csv|
      header_row = ['name', 'price', 'image']
      csv<<header_row
    end
    $i=1
    while $i <= pagination do
      html = open(url + "?p=" + $i.to_s)
      doc = Nokogiri::HTML(html)
      doc.css('.product-container').each do |item|
        item = item.to_s
        new_item = Item.new
        new_item = new_item.parse(item.match(/href="(.*.html)"/)[1])
        CSV.open(file, 'a+') do |csv|
          new_item.unidades.each do |value|
            csv << [new_item.name.to_s + value.weight, value.price, new_item.image]
          end
        end
      end
      $i+=1
    end
  end

  def check_pagination(doc, category)
    puts "Checking pagination"
    item = category.get_content_by_regexp(doc, '.heading-counter',/>(.*)<\//).to_i

    if item%@page_count == 0
      return item/@page_count
    else
      return item/@page_count + 1
    end
  end

end

class Item
  attr_accessor :name, :unidades, :image

  def initialize()
    self.unidades = []
  end

  def parse(url)
    puts "Parsing item..."
    html = open(url)
    doc = Nokogiri::HTML(html)
    parse_name(doc)
    parse_image(doc)
    parse_unidades(doc)
    return self
  end

  def parse_name(content)
    puts "Parsing name..."
    @name = get_content_by_regexp(content, '.product_main_name', /<h1.*>(.*)<\/h1>/)
  end

  def parse_image(content)
    puts("Parsing image...")
    @image = get_content_by_regexp(content, '#bigpic',/src="(.*)".*title/)
  end

  def parse_unidades(content)
    puts "Parsing unidades..."
    html_content = content.css('.attribute_radio_list')

    if html_content.empty?
      price = get_content_by_regexp(content, '#our_price_display', />(.*)<\/span>$/)
      @unidades.push(Unidade.create_instance("", price))
    else
      html_content.css('.label_comb_price').each do |item|
        price_item = get_content_by_regexp(item, '.price_comb', />(.*)<\/span>$/)
        weight_item = get_content_by_regexp(item, '.radio_label', />(.*)<\/span>$/)
        @unidades.push(Unidade.create_instance(weight_item, price_item))
      end
    end
  end


  def get_content_by_regexp(content, selector, regexp)
    get_content_by_selector(content, selector).match(regexp)[1]
  end

  def get_content_by_selector(content, selector)
    content.css(selector).to_s
  end
end

class Unidade
  attr_accessor :weight, :price

  def self.create_instance(weight, price)
    unidade_item = Unidade.new
    unidade_item.price = price
    unidade_item.weight = weight
    return unidade_item
  end
end

category = Category.new
puts("Enter category url")
category.parse(gets.chomp)
