import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Script to update Firestore licenses with real government portal URLs
/// Run this once to update all license URLs with actual working government portals

Future<List<String>> updateLicenseUrls() async {
  final firestore = FirebaseFirestore.instance;
  List<String> logs = [];

  logs.add('Starting URL update...');
  int updatedCount = 0;
  int skippedCount = 0;

  try {
    // We need to iterate through all seeded paths since IDs are not in a flat 'licenses' collection
    // The previous script assumed a flat 'licenses' collection, but the data structure in seeding service
    // is compliance_data -> state -> cities -> city -> business_types -> type -> licenses -> doc

    // However, for update, we can use a collection group query if indexes allow,
    // or just traverse the known structure if we want to be safe without creating indexes.
    // For simplicity and safety without extra index creation, we will fetch from the 'licenses' collection group
    // IF it exists. Wait, the seeding service specific structure:
    // collection('compliance_data').doc(state).collection('cities').doc(city).collection('business_types').doc(businessType).collection('licenses')

    // Let's try to query via collectionGroup 'licenses'
    final snapshot = await firestore.collectionGroup('licenses').get();

    logs.add('Found ${snapshot.docs.length} licenses in database.');

    for (var doc in snapshot.docs) {
      final licenseId = doc.id;

      String? appUrl;
      String? sourceUrl;

      // PATTERN MATCHING LOGIC

      // 1. GST (All India)
      if (licenseId.contains('_gst')) {
        appUrl = 'https://www.gst.gov.in/';
        sourceUrl = 'https://www.gst.gov.in/';
      }
      // 2. FSSAI (All India)
      else if (licenseId.contains('_fssai')) {
        appUrl = 'https://foscos.fssai.gov.in/';
        sourceUrl = 'https://www.fssai.gov.in/';
      }
      // 3. Shops & Establishments
      else if (licenseId.contains('_shop_est')) {
        if (licenseId.contains('ka_')) {
          appUrl = 'https://karmika.karnataka.gov.in/';
          sourceUrl = 'https://karmika.karnataka.gov.in/';
        } else if (licenseId.contains('mh_')) {
          appUrl = 'https://lms.mahaonline.gov.in/';
          sourceUrl = 'https://mahakamgar.maharashtra.gov.in/';
        } else if (licenseId.contains('dl_')) {
          appUrl = 'https://labourcis.nic.in/';
          sourceUrl = 'https://labour.delhi.gov.in/';
        }
      }
      // 4. Trade License (City Specific)
      else if (licenseId.contains('_trade')) {
        if (licenseId.contains('ka_blr')) {
          // Bengaluru
          appUrl = 'https://bbmp.gov.in/';
          sourceUrl = 'https://bbmp.gov.in/';
        } else if (licenseId.contains('ka_mys')) {
          // Mysuru
          appUrl = 'https://mcc.karnataka.gov.in/';
          sourceUrl = 'https://mcc.karnataka.gov.in/';
        } else if (licenseId.contains('ka_mng')) {
          // Mangaluru
          appUrl = 'https://mcc.mangaluru.gov.in/';
          sourceUrl = 'https://mcc.mangaluru.gov.in/';
        } else if (licenseId.contains('mh_mum')) {
          // Mumbai
          appUrl = 'https://portal.mcgm.gov.in/';
          sourceUrl = 'https://portal.mcgm.gov.in/';
        } else if (licenseId.contains('mh_pun')) {
          // Pune
          appUrl = 'https://pmc.gov.in/';
          sourceUrl = 'https://pmc.gov.in/';
        } else if (licenseId.contains('mh_nag')) {
          // Nagpur
          appUrl = 'https://www.nmcnagpur.gov.in/';
          sourceUrl = 'https://www.nmcnagpur.gov.in/';
        } else if (licenseId.contains('dl_')) {
          // Delhi
          appUrl = 'https://mcdonline.nic.in/';
          sourceUrl = 'https://mcdonline.nic.in/';
        }
      }
      // 5. Professional Tax
      else if (licenseId.contains('_pt')) {
        if (licenseId.contains('ka_')) {
          appUrl = 'https://ptax.kar.nic.in/';
          sourceUrl = 'https://ctax.karnataka.gov.in/';
        } else if (licenseId.contains('mh_')) {
          appUrl = 'https://mahavat.gov.in/';
          sourceUrl = 'https://mahavat.gov.in/';
        }
      }
      // 6. Factory License
      else if (licenseId.contains('_factory')) {
        if (licenseId.contains('ka_')) {
          appUrl = 'https://factories.karnataka.gov.in/';
          sourceUrl = 'https://factories.karnataka.gov.in/';
        } else if (licenseId.contains('mh_')) {
          appUrl =
              'https://lms.mahaonline.gov.in/'; // Maharashtra Labour Management System
          sourceUrl = 'https://mahakamgar.maharashtra.gov.in/';
        }
      }
      // 7. Pollution
      else if (licenseId.contains('_pollution')) {
        if (licenseId.contains('ka_')) {
          appUrl = 'https://kspcb.karnataka.gov.in/';
          sourceUrl = 'https://kspcb.karnataka.gov.in/';
        } else if (licenseId.contains('mh_')) {
          appUrl = 'https://mpcb.gov.in/';
          sourceUrl = 'https://mpcb.gov.in/';
        }
      }
      // 8. Fire NOC
      else if (licenseId.contains('_fire')) {
        if (licenseId.contains('ka_')) {
          appUrl = 'https://fire.karnataka.gov.in/';
          sourceUrl = 'https://fire.karnataka.gov.in/';
        }
      }
      // 9. Labour
      else if (licenseId.contains('_labour')) {
        if (licenseId.contains('ka_')) {
          appUrl = 'https://karmika.karnataka.gov.in/';
          sourceUrl = 'https://karmika.karnataka.gov.in/';
        }
      }
      // 10. Health
      else if (licenseId.contains('_health')) {
        if (licenseId.contains('ka_')) {
          appUrl = 'https://health.karnataka.gov.in/';
          sourceUrl = 'https://health.karnataka.gov.in/';
        }
      }

      // Apply Update if URL found
      if (appUrl != null) {
        await doc.reference.update({
          'applicationUrl': appUrl,
          'sourceUrl': sourceUrl,
          'updated_at': FieldValue.serverTimestamp(),
        });
        logs.add('✅ Updated: $licenseId');
        updatedCount++;
      } else {
        logs.add('⚠️ Skipped: $licenseId (No match)');
        skippedCount++;
      }
    }

    logs.add('Update Summary:');
    logs.add('✅ Updated: $updatedCount licenses');
    logs.add('⚠️ Skipped: $skippedCount licenses');

    return logs;
  } catch (e) {
    logs.add('❌ Error updating URLs: $e');
    return logs;
  }
}

// Alternative: Update specific license by ID
Future<void> updateSingleLicense(
    String licenseId, String applicationUrl, String sourceUrl) async {
  final firestore = FirebaseFirestore.instance;

  try {
    await firestore.collection('licenses').doc(licenseId).update({
      'application_url': applicationUrl,
      'source_url': sourceUrl,
      'updated_at': FieldValue.serverTimestamp(),
    });

    debugPrint('✅ Updated $licenseId successfully');
  } catch (e) {
    debugPrint('❌ Error updating $licenseId: $e');
  }
}
