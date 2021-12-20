// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.6.11;
import "https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-contracts/release-v3.2.0/contracts/access/Ownable.sol";

contract Voting is Ownable {

   /* contract deployer is administrator */
   address private administrator;

   /* the winner */
   Proposal public winningProposal;
   mapping(address=> bool) whitelist;
   
   mapping(address => Voter) public voters;
   
   Proposal[] public proposals;
   WorkflowStatus private status;

struct Voter {
  bool isRegistered;
  bool hasVoted;
  uint votedProposalId;
}

struct Proposal {
  string description;
  uint voteCount;
}

enum WorkflowStatus {
RegisteringVoters,
ProposalsRegistrationStarted,
ProposalsRegistrationEnded,
VotingSessionStarted,
VotingSessionEnded,
VotesTallied
}

/* events */

event VoterRegistered(address voterAddress);
event ProposalsRegistrationStarted();
event ProposalsRegistrationEnded();
event ProposalRegistered(uint proposalId);
event VotingSessionStarted();
event VotingSessionEnded();
event Voted (address voter, uint proposalId);
event VotesTallied();
event WorkflowStatusChange(WorkflowStatus previousStatus, WorkflowStatus newStatus);


    /**
     * @dev Set contract deployer as administrator
     */
    constructor() public {
        administrator = msg.sender;
    }

   function add(address _address) onlyOwner public  {
       whitelist[_address]=true;
      

   }

 function startRegistering() onlyOwner public  {
       
      status=WorkflowStatus.RegisteringVoters;

   }

   function register() public {
                
     require(status ==WorkflowStatus.RegisteringVoters, "Registering closed");
     require(whitelist[msg.sender]==true, "Not allowed");  
      voters[msg.sender] = Voter(true,false,0);
    
      
      emit VoterRegistered(msg.sender);
   }

   function startProposalRegistration() onlyOwner public  {

      require(status==WorkflowStatus.RegisteringVoters, "Voters must register first");
       status=WorkflowStatus.ProposalsRegistrationStarted;
       emit WorkflowStatusChange( WorkflowStatus.RegisteringVoters,WorkflowStatus.ProposalsRegistrationStarted);
       delete proposals;
       
      emit ProposalsRegistrationStarted();

   }

   function addProposal(string memory _description) public {

      require(status ==WorkflowStatus.ProposalsRegistrationStarted, "Proposal registration not available");
      require(whitelist[msg.sender]==true, "Not allowed");      
      proposals.push(Proposal(_description,0));
      emit ProposalRegistered(proposals.length);
   }

     function stopProposalRegistration() onlyOwner public  {
     require(status ==WorkflowStatus.ProposalsRegistrationStarted, "Proposal registration not started");
     require(proposals.length >1, "You need at least 2 Proposals");
       status=WorkflowStatus.ProposalsRegistrationEnded;
     emit WorkflowStatusChange(WorkflowStatus.ProposalsRegistrationStarted,WorkflowStatus.ProposalsRegistrationEnded);  
      emit ProposalsRegistrationEnded();

   }

   function startVoting() onlyOwner public {
    require(status ==WorkflowStatus.ProposalsRegistrationEnded, "Proposal registration not ended");
    status=WorkflowStatus.VotingSessionStarted;
    emit WorkflowStatusChange(WorkflowStatus.ProposalsRegistrationEnded,WorkflowStatus.VotingSessionStarted); 
      emit VotingSessionStarted();
   }

  function stopVoting() onlyOwner public {
    require(status ==WorkflowStatus.VotingSessionStarted, "Voting session not started");
    status=WorkflowStatus.VotingSessionEnded;
    emit WorkflowStatusChange(WorkflowStatus.VotingSessionStarted,WorkflowStatus.VotingSessionEnded); 
      emit VotingSessionEnded();
   }

      function vote(uint proposalId) public {

      require(status ==WorkflowStatus.VotingSessionStarted, "Voting not started");
      require(proposalId<(proposals.length-1) && proposalId>=0, "Unknown proposal");      
      require(voters[msg.sender].isRegistered, "You are not registered"); 
      require(!voters[msg.sender].hasVoted, "You have already vote"); 
      voters[msg.sender].votedProposalId=proposalId;
      proposals[proposalId].voteCount++;
      emit Voted (msg.sender, proposalId);
   }

   function computeWinner() public onlyOwner {

      require(status ==WorkflowStatus.VotingSessionEnded, "Voting not ended");
              uint winningVoteCount = 0;
        for (uint p = 0; p < proposals.length; p++) {
            if (proposals[p].voteCount > winningVoteCount) {
                winningVoteCount = proposals[p].voteCount;
                winningProposal= proposals[p];
            }
        }
    status=WorkflowStatus.VotesTallied;  
    emit WorkflowStatusChange(WorkflowStatus.VotingSessionEnded,WorkflowStatus.VotesTallied);
          
   }

   function getWinner() public view returns (uint winningProposal_ ) {

      require(status ==WorkflowStatus.VotesTallied, "Voting not tallied");
              uint winningVoteCount = 0;
        for (uint p = 0; p < proposals.length; p++) {
            if (proposals[p].voteCount > winningVoteCount) {
                winningVoteCount = proposals[p].voteCount;
                winningProposal_ = p;
            }
        }
          
   }
}
