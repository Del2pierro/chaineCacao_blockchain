const axios = require('axios');

async function testTransaction() {
    console.log('Testing transaction submission with new user cooperateur_v2...');
    
    try {
        const response = await axios.post('http://localhost:3000/invoke', {
            function: 'CreateLot',
            args: ['LOT-GATEWAY-001', 'Cacao Premium', '1000', 'Producteur de Test']
        }, {
            headers: {
                'X-Org-Name': 'producteurs',
                'X-User-ID': 'cooperateur_v2'
            }
        });
        
        console.log('Response:', response.data);
    } catch (error) {
        console.error('Error:', error.response ? error.response.data : error.message);
    }
}

testTransaction();
