. configs/globals.cfg

# Where everything that are not scripts are kept.
mkdir -p data/nfts

# The jpegs! They will be inscribed by chronoligcal order (as hardocded presently)
mkdir -p data/INSCRIBED

# The list of addresses that users will deposit funds into.
touch data/deposit_addresses.txt

# The list of addresses a user expects us to send an nft to
touch data/btc_receive_addresses.txt
touch data/owners_pending.txt

# Folder to maintain the currenet addresses that are waiting on deposits.
mkdir -p data/watching/

# Make all the required deposit addresses
start_nft=1
end_nft=20
echo "Use these addresses as dummy receiver addresses on the website, they can be sent an nft:"
for n in $(seq -w $start_nft $end_nft);
  do ord --signet wallet receive | jq -r '.address' >> data/deposit_addresses.txt
  echo "$n" > data/nfts/$n.txt  
done

cp -v data/deposit_addresses.txt data/available_addresses.txt