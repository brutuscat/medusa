$:.unshift(File.dirname(__FILE__))
require 'spec_helper'

require 'medusa/storage/redis.rb'

module Medusa
  describe Storage do

    describe ".Hash" do
      it "returns a Hash adapter" do
        Medusa::Storage.Hash.should be_an_instance_of(Hash)
      end
    end

    describe ".Redis" do
      it "returns a Redis adapter" do
        store = Medusa::Storage.Redis
        store.should be_an_instance_of(Medusa::Storage::Redis)
        store.close
      end
    end

    module Storage
      shared_examples_for "storage engine" do

        before(:each) do
          @url = SPEC_DOMAIN
          @page = Page.new(URI(@url))
        end

        it "should implement [] and []=" do
          @store.should respond_to(:[])
          @store.should respond_to(:[]=)

          @store[@url] = @page
          @store[@url].url.should == URI(@url)
        end

        it "should implement has_key?" do
          @store.should respond_to(:has_key?)

          @store[@url] = @page
          @store.has_key?(@url).should == true

          @store.has_key?('missing').should == false
        end

        it "should implement delete" do
          @store.should respond_to(:delete)

          @store[@url] = @page
          @store.delete(@url).url.should == @page.url
          @store.has_key?(@url).should  == false
        end

        it "should implement keys" do
          @store.should respond_to(:keys)

          urls = [SPEC_DOMAIN, SPEC_DOMAIN + 'test', SPEC_DOMAIN + 'another']
          pages = urls.map { |url| Page.new(URI(url)) }
          urls.zip(pages).each { |arr| @store[arr[0]] = arr[1] }

          (@store.keys - urls).should == []
        end

        it "should implement each" do
          @store.should respond_to(:each)

          urls = [SPEC_DOMAIN, SPEC_DOMAIN + 'test', SPEC_DOMAIN + 'another']
          pages = urls.map { |url| Page.new(URI(url)) }
          urls.zip(pages).each { |arr| @store[arr[0]] = arr[1] }

          result = {}
          @store.each { |k, v| result[k] = v }
          (result.keys - urls).should == []
          (result.values.map { |page| page.url.to_s } - urls).should == []
        end

        it "should implement merge!, and return self" do
          @store.should respond_to(:merge!)

          hash = {SPEC_DOMAIN => Page.new(URI(SPEC_DOMAIN)),
                  SPEC_DOMAIN + 'test' => Page.new(URI(SPEC_DOMAIN + 'test'))}
          merged = @store.merge! hash
          hash.each { |key, value| @store[key].url.to_s.should == key }

          merged.should === @store
        end

        it "should correctly deserialize nil redirect_to when loading" do
          @page.redirect_to.should be_nil
          @store[@url] = @page
          @store[@url].redirect_to.should be_nil
        end
      end

      describe Storage::Redis do
        it_should_behave_like "storage engine"

        before(:each) do
          @store = Storage.Redis
        end

        after(:each) do
          @store.close
        end
      end

    end
  end
end