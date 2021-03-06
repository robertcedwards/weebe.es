# Copyright (c) 2009, Adrian Kosmaczewski / akosma software
# All rights reserved.
# BSD License. See LICENSE.txt for details.

class ItemsController < ApplicationController

  def redirect
    @item = Item.find_by_shortened(params[:shortened])
    if @item
      redirect_to @item.original
    else
      redirect_to :shorten
    end
  end

  def shorten
    @host = request.host_with_port

    if !params.has_key?(:url) && !params.has_key?(:reverse)
      render :template => "items/new"
      return
    end

    if params.has_key?(:reverse)
      reverse = params[:reverse]

      if reverse.length == 0
        render_error "items/invalid"
        return
      end

      @item = Item.find_by_shortened(reverse)
      if not @item
        render_error "items/not_found"
        return
      end
    else
      url = params[:url]
      short = nil
    
      if params.has_key?(:short)
        short = CGI::escape(params[:short])
      end
    
      if url.length == 0
        render_error "items/invalid"
        return
      end

      if !url.starts_with?("http://")
        render_error "items/invalid"
        return
      end

      if is_already_shortened_url?(url)
        render_error "items/invalid"
        return
      end


      
      @item = Item.find_by_original(url)
      if not @item
        @item = Item.new
        @item.original = url
        @item.shortened = short
      end
      @item.save
    end

    respond_to do |format|
      format.html do
        @long_url = [@item.original]
        @short_url = [@item.shortened]
        @twitter_url = ["http://twitter.com/home?status=", @short_url].join
        newline = "%0D%0A"
        @email_url = ["mailto:?subject=Check out this URL shortened by cortito",
                      "&body=Check out this URL: ", @short_url, newline, 
                      "Originally: ", @item.original, newline, newline, 
                      "Shortened by cortito http://url.akosma.com/", newline, 
                      "by akosma software http://akosma.com/", newline].join
        @echofon_url = ["echofon:", @short_url].join
        render :template => "items/show"
      end
      format.xml { render_for_api }
      format.js { render_for_api }
    end

  end

private

  def render_error(error_template)
    url = ""
    if params.has_key?(:url)
      url = params[:url]
    end
    respond_to do |format|
      format.html { render :template => error_template }
      format.xml { render :text => url }
      format.js { render :text => url }
    end
  end

  def render_for_api
    if params.has_key?(:reverse)
      render :text => @item.original
    else
      
    end
  end

  def is_already_shortened_url?(url)
    shortened_url_prefix = ["http://tinyurl.com/", "http://url.akosma.com/",
      "http://u.nu/", "http://snipurl.com/", "http://readthisurl.com/",
      "http://doiop.com/", "http://urltea.com/", "http://dwarfurl.com/", 
      "http://memurl.com/", "http://shorl.com/", "http://traceurl.com/", 
      "http://bit.ly/"]
    
    shortened_url_prefix.each do |prefix|
      if url.starts_with?(prefix)
        return true
      end
    end
    return false
  end

end
