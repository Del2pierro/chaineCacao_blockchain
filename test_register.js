async function testRegister() {
    try {
        console.log('Testing registration of cooperateur_test...');
        const response = await fetch('http://localhost:3000/register', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                userId: 'cooperateur_v2',
                orgName: 'producteurs',
                role: 'client'
            })
        });
        const data = await response.json();
        console.log('Response:', data);
    } catch (error) {
        console.error('Error:', error.message);
    }
}

testRegister();
