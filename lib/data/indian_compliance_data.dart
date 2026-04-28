/// Comprehensive Database of Indian Commercial Laws & Compliance
/// Covering: Central Laws, Karnataka, Maharashtra, Delhi
/// Business Types: Retail, Food, Manufacturing, Services
library;

const List<Map<String, dynamic>> indianComplianceData = [
  // ============================================
  // CENTRAL LAWS (Applicable everywhere)
  // ============================================
  {
    'id': 'gst_reg',
    'name': 'GST Registration',
    'official_name': 'Goods and Services Tax Registration',
    'department': 'Central Board of Indirect Taxes',
    'description':
        'Mandatory for businesses with turnover > ₹20L (Services) or ₹40L (Goods).',
    'is_mandatory': true,
    'renewal_cycle': 'Lifetime',
    'fee': 0,
    'penalty_description': '₹10,000 or 10% of tax due, whichever is higher.',
    'grace_period_days': 0,
    'application_url': 'https://reg.gst.gov.in',
    'helpline': '1800-103-4786',
    'required_documents': [
      'PAN Card',
      'Aadhar Card',
      'Proof of Business Address',
      'Bank Account Proof'
    ],
    'processing_time': '7 working days',
    'states': ['All'],
    'business_types': ['All'],
  },
  {
    'id': 'udyam_reg',
    'name': 'Udyam Registration (MSME)',
    'official_name': 'Udyam Registration',
    'department': 'Ministry of MSME',
    'description':
        'Essential for availaing government subsidies and priority lending.',
    'is_mandatory': false,
    'renewal_cycle': 'Lifetime',
    'fee': 0,
    'penalty_description': 'None (Voluntary but recommended)',
    'grace_period_days': 0,
    'application_url': 'https://udyamregistration.gov.in',
    'helpline': '011-23063800',
    'required_documents': ['Aadhar Number', 'PAN Number'],
    'processing_time': 'Instant',
    'states': ['All'],
    'business_types': ['All'],
  },
  {
    'id': 'fssai_basic',
    'name': 'FSSAI Registration (Basic)',
    'official_name': 'FSSAI Basic Registration',
    'department': 'Food Safety and Standards Authority of India',
    'description':
        'Mandatory for petty food businesses with turnover < ₹12 Lakhs/year.',
    'is_mandatory': true,
    'renewal_cycle': '1-5 Years',
    'fee': 100,
    'penalty_description': 'Up to ₹25,000 imprisonment.',
    'grace_period_days': 30,
    'application_url': 'https://foscos.fssai.gov.in',
    'helpline': '1800-112-100',
    'required_documents': ['Photo', 'Govt ID Proof'],
    'processing_time': '7-30 days',
    'states': ['All'],
    'business_types': ['food_beverage', 'retail_shop'],
  },
  {
    'id': 'fssai_state',
    'name': 'FSSAI State License',
    'official_name': 'FSSAI State License',
    'department': 'Food Safety and Standards Authority of India',
    'description':
        'Mandatory for food businesses with turnover between ₹12L - ₹20Cr.',
    'is_mandatory': true,
    'renewal_cycle': '1-5 Years',
    'fee': 2000,
    'penalty_description': 'Up to ₹5 Lakhs fine and 6 months imprisonment.',
    'grace_period_days': 30,
    'application_url': 'https://foscos.fssai.gov.in',
    'helpline': '1800-112-100',
    'required_documents': [
      'Unit Layout',
      'Equipment List',
      'NOC from Municipality',
      'Partnership Deed'
    ],
    'processing_time': '60 days',
    'states': ['All'],
    'business_types': ['food_beverage', 'manufacturing'],
  },
  {
    'id': 'epf_reg',
    'name': 'EPF Registration',
    'official_name': 'Employees Provident Fund',
    'department': 'EPFO',
    'description': 'Mandatory for organizations with 20+ employees.',
    'is_mandatory': true,
    'renewal_cycle': 'Lifetime',
    'fee': 0,
    'penalty_description': 'Interest + Damages on arrears.',
    'grace_period_days': 0,
    'application_url': 'https://unifiedportal-emp.epfindia.gov.in',
    'helpline': '1800-118-005',
    'required_documents': [
      'PAN',
      'Incorporation Certificate',
      'Employee Details'
    ],
    'processing_time': '3-7 days',
    'states': ['All'],
    'business_types': ['manufacturing', 'service_provider', 'retail_shop'],
  },
  {
    'id': 'esi_reg',
    'name': 'ESI Registration',
    'official_name': 'Employees State Insurance',
    'department': 'ESIC',
    'description':
        'Mandatory for units with 10+ employees earning < ₹21,000/month.',
    'is_mandatory': true,
    'renewal_cycle': 'Lifetime',
    'fee': 0,
    'penalty_description': 'Simple imprisonment up to 2 years + fine.',
    'grace_period_days': 0,
    'application_url': 'https://www.esic.in',
    'helpline': '1800-112-526',
    'required_documents': ['Business Registration', 'Employee List', 'PAN'],
    'processing_time': '10 days',
    'states': ['All'],
    'business_types': ['manufacturing', 'service_provider'],
  },

  // ============================================
  // KARNATAKA (Bangalore)
  // ============================================
  {
    'id': 'ka_shop_act',
    'name': 'Karnataka Shop & Establishment',
    'official_name':
        'Karnataka Shops and Commercial Establishments Registration',
    'department': 'Department of Labour, Karnataka',
    'description':
        'Mandatory for all shops/offices to regulate working conditions.',
    'is_mandatory': true,
    'renewal_cycle': '5 Years',
    'fee': 300,
    'penalty_description': 'Fine up to ₹20,000 for non-compliance.',
    'grace_period_days': 30,
    'application_url': 'https://ekarmika.karnataka.gov.in',
    'helpline': '080-22221111',
    'required_documents': [
      'Rental Agreement',
      'PAN',
      'Incorporation Certificate'
    ],
    'processing_time': '30 days',
    'states': ['Karnataka'],
    'business_types': ['All'],
  },
  {
    'id': 'ka_trade_license',
    'name': 'BBMP Trade License',
    'official_name': 'Health Trade License (BBMP)',
    'department': 'BBMP Health Department',
    'description':
        'Required to operate specific trades affecting public health in Bangalore.',
    'is_mandatory': true,
    'renewal_cycle': 'Yearly',
    'fee': 5000,
    'penalty_description': 'Closure of business + Heavy fine.',
    'grace_period_days': 45,
    'application_url': 'http://bbmp.gov.in/tradelicense',
    'helpline': '080-22660000',
    'required_documents': [
      'Previous Year Receipt',
      'Property Tax Receipt',
      'NOC from Neighbors'
    ],
    'processing_time': '15 days',
    'states': ['Karnataka'],
    'business_types': ['retail_shop', 'food_beverage', 'manufacturing'],
  },
  {
    'id': 'ka_pro_tax',
    'name': 'Professional Tax (PT)',
    'official_name': 'Karnataka Professional Tax Registration',
    'department': 'Commercial Taxes Department',
    'description': 'Tax on professions, trades, callings and employments.',
    'is_mandatory': true,
    'renewal_cycle': 'Yearly',
    'fee': 2500,
    'penalty_description': 'Interest at 1.25% per month.',
    'grace_period_days': 0,
    'application_url': 'https://pt.kar.nic.in',
    'helpline': '1800-425-6300',
    'required_documents': ['Certificate of Incorporation', 'Address Proof'],
    'processing_time': '1-3 days',
    'states': ['Karnataka'],
    'business_types': ['service_provider', 'manufacturing', 'retail_shop'],
  },
  {
    'id': 'ka_fire_noc',
    'name': 'Fire NOC',
    'official_name': 'Karnataka Fire Safety Compliance',
    'department': 'Karnataka State Fire and Emergency Services',
    'description':
        'Mandatory for high-rise buildings and hazardous industries.',
    'is_mandatory': true,
    'renewal_cycle': '2 Years',
    'fee': 10000,
    'penalty_description': 'Sealing of Premises.',
    'grace_period_days': 0,
    'application_url': 'https://ksfes.karnataka.gov.in',
    'helpline': '101',
    'required_documents': [
      'Building Plan',
      'Ownership Proof',
      'Fire Safety Audit'
    ],
    'processing_time': '30-90 days',
    'states': ['Karnataka'],
    'business_types': ['manufacturing', 'food_beverage'],
  },

  // ============================================
  // MAHARASHTRA (Mumbai)
  // ============================================
  {
    'id': 'mh_shop_act',
    'name': 'Gumasta License',
    'official_name': 'Maharashtra Shops and Establishments Registration',
    'department': 'BMC / Municipal Corporation',
    'description':
        'Essential license to open any shop or office in Maharashtra.',
    'is_mandatory': true,
    'renewal_cycle': 'Lifetime (Registration) / Yearly (License)',
    'fee': 2500,
    'penalty_description': 'Fine of ₹5000 per day for continuing offense.',
    'grace_period_days': 30,
    'application_url': 'https://lms.mahaonline.gov.in',
    'helpline': '022-2269-1234',
    'required_documents': [
      'Address Proof',
      'PAN',
      'Photo of Shop with Name Board'
    ],
    'processing_time': '7-14 days',
    'states': ['Maharashtra'],
    'business_types': ['All'],
  },
  {
    'id': 'mh_pt_ec',
    'name': 'Professional Tax (EC)',
    'official_name': 'Professional Tax Enrollment Certificate',
    'department': 'Mahavat',
    'description': 'Tax liability for the business entity itself.',
    'is_mandatory': true,
    'renewal_cycle': 'Yearly',
    'fee': 2500,
    'penalty_description': '10% penalty on tax due.',
    'grace_period_days': 30,
    'application_url': 'https://mahagst.gov.in',
    'helpline': '1800-225-900',
    'required_documents': ['PAN', 'Utility Bill'],
    'processing_time': '1 day',
    'states': ['Maharashtra'],
    'business_types': ['All'],
  },

  // ============================================
  // DELHI
  // ============================================
  {
    'id': 'dl_shop_act',
    'name': 'Delhi Shop & Establishment',
    'official_name': 'Delhi Shops and Establishments Registration',
    'department': 'Department of Labour, NCT of Delhi',
    'description':
        'Mandatory registration within 90 days of opening establishment.',
    'is_mandatory': true,
    'renewal_cycle': 'Lifetime',
    'fee': 0,
    'penalty_description': 'Prosecution in court.',
    'grace_period_days': 0,
    'application_url': 'https://labourcis.nic.in',
    'helpline': '011-23951234',
    'required_documents': ['Postcard size photo of shop', 'PAN', 'ID Proof'],
    'processing_time': 'Instant',
    'states': ['Delhi'],
    'business_types': ['All'],
  },
  {
    'id': 'dl_factory_license',
    'name': 'Delhi Factory License',
    'official_name': 'License under Factories Act, 1948',
    'department': 'Labour Department',
    'description':
        'Mandatory for factories using power (10+ workers) or without power (20+ workers).',
    'is_mandatory': true,
    'renewal_cycle': 'Yearly',
    'fee': 5000,
    'penalty_description': 'Imprisonment up to 2 years.',
    'grace_period_days': 60,
    'application_url': 'https://edistrict.delhigovt.nic.in',
    'helpline': '1031',
    'required_documents': [
      'Factory Plan Approval',
      'Land Papers',
      'Machinery List'
    ],
    'processing_time': '30-45 days',
    'states': ['Delhi'],
    'business_types': ['manufacturing'],
  },

  // ============================================
  // SPECIFIC SECTORS
  // ============================================
  {
    'id': 'music_license',
    'name': 'Music License',
    'official_name': 'IPRS / PPL License',
    'department': 'IPRS Ltd.',
    'description':
        'Required for playing copyrighted music in restaurants/cafes.',
    'is_mandatory': true,
    'renewal_cycle': 'Yearly',
    'fee': 10000,
    'penalty_description': 'Copyright infringement lawsuit.',
    'grace_period_days': 0,
    'application_url': 'https://iprs.org',
    'helpline': '022-26736666',
    'required_documents': ['Seating Capacity Proof', 'Premises details'],
    'processing_time': '15 days',
    'states': ['All'],
    'business_types': ['food_beverage', 'retail_shop'],
  },
  {
    'id': 'pollution_consent',
    'name': 'Pollution Control Consent',
    'official_name': 'Consent to Establish / Operate (CTO)',
    'department': 'State Pollution Control Board',
    'description':
        'Mandatory for manufacturing units emitting waste/effluents.',
    'is_mandatory': true,
    'renewal_cycle': '3-5 Years',
    'fee': 15000,
    'penalty_description': 'Closure order + Heavy environmental damage fine.',
    'grace_period_days': 60,
    'application_url': 'https://cpcb.nic.in',
    'helpline': '011-43102030',
    'required_documents': [
      'Site Plan',
      'Project Report',
      'Waste Management Plan'
    ],
    'processing_time': '120 days',
    'states': ['All'],
    'business_types': ['manufacturing'],
  },
];
