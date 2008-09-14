require File.dirname(__FILE__) + '/spec_helper'

describe Protocol do

  before(:each) do
    @protocol_class = Class.new{include Protocol}
    @connection = @protocol_class.new
    
    #
    # Mock stubs
    #
    @local_uuid = local_uuid = "local-uuid"
    @remote_uuid = remote_uuid = "remote-uuid"
    
    @connection.stub!(:send_marshalled_message).and_return(nil)
    @local_pid = local_pid = mock("Pid", :uuid => @local_uuid, 
                                         :options => {:uuid => @local_uuid})

    local_pid.instance_eval do
      stub!(:_register_pid).and_return{|pid| pid}
      stub!(:connected).and_return(nil)
      stub!(:handshake_failed).and_return(nil)
    end
    
    @remote_pid = remote_pid = mock("RemotePid", :uuid => @remote_uuid, 
                                                 :options => {:uuid => @remote_uuid})
  end
  

  describe "handshake" do
    before(:each) do
      @handshake_args = Object.new # unique object
      @connection.should_receive(:send_marshalled_message).once.with([:handshake, @handshake_args])
    end
    
    it "should verify handshake format" do
      @connection.send_handshake_message(@handshake_args)
    end
  end
  
  
  describe "broken connection", :shared => true do
    it "should reset remote_pid on error" do
      @rpid.should be_nil
    end
  end
  
  
  describe "successful connection" do
    before(:each) do
      #
      # Mock expectations
      #
      rpid = an_instance_of(RemotePid)
      @local_pid.should_receive(:_register_pid).once.with(rpid).and_return{|pid| pid}
      @local_pid.should_receive(:connected).once.with(rpid)
      @connection.should_receive(:send_handshake_message).once.with(@local_pid.options)
      #
      # Init
      #
      @connection.address = em_addr.parsed_uri
      @connection.local_pid = @local_pid
      @connection.post_init
    # server doesn't receive this:  @connection.connection_completed
      @connection.receive_marshalled_message([:handshake, @remote_pid.options])
      @rpid = @connection.remote_pid
    end
    
    it "should verify mocks" do
    end
    
    it "should have #remote_pid" do
      @rpid.should_not be_nil
    end
    
    it "should assign correct UUID to remote_pid" do
      @rpid.uuid.should == @remote_pid.uuid
    end
    
    it "should assign correct options to remote_pid" do
      @rpid.options.should == @remote_pid.options
    end
    
    describe "broken" do
      
      before(:each) do
        #
        # Mock expectations
        #
        @local_pid.should_receive(:_unregister_pid).once.with(@rpid).and_return{|pid| pid}
        @local_pid.should_receive(:disconnected).once.with(@rpid)
        #
        # Init
        #
        @connection.unbind
        @rpid = @connection.remote_pid
      end
      
      it_should_behave_like "broken connection"
    end
    
  end
  
  
  describe "connection refusal" do
    before(:each) do
      #
      # Mock expectations
      #
      @local_pid.should_receive(:connecting_failed).once.with(@connection)
      @connection.should_not_receive(:send_handshake_message)
      #
      # Init
      #
      @connection.address = em_addr.parsed_uri
      @connection.local_pid = @local_pid
      @connection.post_init
      @connection.unbind
      @rpid = @connection.remote_pid
    end
    
    it_should_behave_like "broken connection"
  end


  describe "failed handshake" do
    before(:each) do
      #
      # Mock expectations
      #
      @not_a_handshake = :not_a_handshake
      @local_pid.should_receive(:handshake_failed).once.with(@connection, @not_a_handshake)
      @connection.should_receive(:send_handshake_message).once.with(@local_pid.options)
      #
      # Init
      #
      @connection.address = em_addr.parsed_uri
      @connection.local_pid = @local_pid
      @connection.post_init
      @connection.connection_completed
      @connection.receive_marshalled_message(@not_a_handshake)
      @rpid = @connection.remote_pid
    end
    
    it_should_behave_like "broken connection"
  end
  
end