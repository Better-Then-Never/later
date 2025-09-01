const functions = require('firebase-functions');
const admin = require('firebase-admin');

// Initialize Firebase Admin
admin.initializeApp();

exports.getUserData = functions.https.onRequest(async (req, res) => {
    // Set CORS headers
    res.set('Access-Control-Allow-Origin', '*');
    res.set('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
    res.set('Access-Control-Allow-Headers', 'Content-Type');

    if (req.method === 'OPTIONS') {
        res.status(200).end();
        return;
    }

    if (req.method !== 'GET') {
        res.status(405).json({ error: 'Method not allowed' });
        return;
    }

    try {
        const userId = req.query.userId;

        if (!userId) {
            res.status(400).json({ error: 'User ID is required' });
            return;
        }

        console.log('Fetching data for userId:', userId);

        // Fetch user data from Firebase Auth
        const userRecord = await admin.auth().getUser(userId);

        // Fetch additional data from Firestore
        const db = admin.firestore();
        const userDoc = await db.collection('users').doc(userId).get();

        let displayName = userRecord.displayName;
        let photoURL = userRecord.photoURL;

        // If no display name in Auth, try to get from Firestore
        if (!displayName && userDoc.exists) {
            const userData = userDoc.data();
            displayName = userData.displayName || userData.name || userData.firstName;
        }

        // Try to find profile image in Firebase Storage
        const bucket = admin.storage().bucket();
        
        // First, let's try to list files in the directory to see what's actually there
        try {
            const [files] = await bucket.getFiles({
                prefix: `userdata/${userId}/assets/images/`
            });
            
            console.log('Files found in directory:');
            files.forEach(file => {
                console.log('- File name:', file.name);
            });
            
            // Look for profile image file
            const profileImageFile = files.find(file => 
                file.name.includes('profile_image') || 
                file.name.includes('profile')
            );
            
            if (profileImageFile) {
                console.log('Found profile image file:', profileImageFile.name);
                
                // Make the file publicly readable
                await profileImageFile.makePublic();
                
                // Get the public URL
                photoURL = `https://storage.googleapis.com/${bucket.name}/${profileImageFile.name}`;
                console.log('Generated public URL:', photoURL);
            } else {
                console.log('No profile image file found');
            }
            
        } catch (listError) {
            console.error('Error listing files:', listError);
        }

        console.log('Final photoURL:', photoURL);

        res.json({
            displayName: displayName || 'Your friend',
            email: userRecord.email,
            photoURL: photoURL,
            debug: {
                userId: userId,
                foundImage: !!photoURL
            }
        });

    } catch (error) {
        console.error('Error fetching user data:', error);
        res.status(500).json({
            error: 'Failed to fetch user data',
            displayName: 'Your friend'
        });
    }
});